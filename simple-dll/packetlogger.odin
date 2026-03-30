#+build windows
package payload

import "base:runtime"
import "core:mem"
import "core:strings"
import win "core:sys/windows"

HOOK_SIZE :: 5
HOOK_SIZE_SEND :: 6

// Global state
qRecv: ^SafeQueue
qSend: ^SafeQueue
SendAddy: uintptr
RecvHookAddy: uintptr
TNTClient: uintptr
originalCallAddy: uintptr
jmpBackAddy: uintptr
originalBytes: [10]byte

sendTrampoline_addr: uintptr
sendOriginalBytes: [10]byte
trampoline_addr: uintptr
send_packet_proc: proc "c" (tnt_client: uintptr, packet: cstring, send_addy: uintptr)

// The Odin hook receiver that pushes to sent queue with filtering
@(export)
odin_custom_send :: proc "c" (packet_ptr: cstring) {
	context = runtime.default_context()

	if packet_ptr != nil && qSend != nil {
		packet_str := string(packet_ptr)
		push(qSend, packet_str)
	}
}

// The Odin hook receiver that pushes to our queue
@(export)
odin_custom_recv :: proc "c" (packet_ptr: cstring) {
	// Odin needs an active context when called from unmanaged thread
	context = runtime.default_context()

	if packet_ptr != nil && qRecv != nil {
		packet_str := string(packet_ptr)
		// SafeQueue's push handles taking a copy of the string data internally
		push(qRecv, packet_str)
	}
}

init_packetlogger :: proc(recv_queue, send_queue: ^SafeQueue) {
	qRecv = recv_queue
	qSend = send_queue
	RecvHookAddy = global_addrs.RecvHookAddy
	TNTClient = global_addrs.TNTClient
	SendAddy = global_addrs.SendAddy

	jmpBackAddy = RecvHookAddy + HOOK_SIZE

	// Calculate original call destination
	callArgAddy := (cast(^u32)(RecvHookAddy + 1))^
	// originalCallAddy = RecvHookAddy + offset + 5
	originalCallAddy = RecvHookAddy + uintptr(callArgAddy) + HOOK_SIZE

	// Save original bytes
	copy(originalBytes[:HOOK_SIZE], (cast([^]byte)RecvHookAddy)[:HOOK_SIZE])

	// ----------------------------------------------------
	// 1. Generate trampoline for CustomRecv
	// ----------------------------------------------------
	trampoline_addr = cast(uintptr)win.VirtualAlloc(
		nil,
		128,
		win.MEM_COMMIT | win.MEM_RESERVE,
		win.PAGE_EXECUTE_READWRITE,
	)

	if trampoline_addr != 0 {
		t := cast([^]byte)trampoline_addr
		idx: uintptr = 0

		t[idx] = 0x60; idx += 1 // pushad
		t[idx] = 0x9C; idx += 1 // pushfd
		t[idx] = 0x52; idx += 1 // push edx (where packet string pointer is stored)

		// call odin_custom_recv
		t[idx] = 0xE8; idx += 1
		offset1 := u32(cast(uintptr)rawptr(odin_custom_recv) - (trampoline_addr + idx + 4))
		(cast(^u32)(&t[idx]))^ = offset1
		idx += 4

		// add esp, 4
		t[idx] = 0x83; idx += 1
		t[idx] = 0xC4; idx += 1
		t[idx] = 0x04; idx += 1

		t[idx] = 0x9D; idx += 1 // popfd
		t[idx] = 0x61; idx += 1 // popad

		// call originalCallAddy
		t[idx] = 0xE8; idx += 1
		offset2 := u32(originalCallAddy - (trampoline_addr + idx + 4))
		(cast(^u32)(&t[idx]))^ = offset2
		idx += 4

		// jmp jmpBackAddy
		t[idx] = 0xE9; idx += 1
		offset3 := u32(jmpBackAddy - (trampoline_addr + idx + 4))
		(cast(^u32)(&t[idx]))^ = offset3
		idx += 4
	} else {
		log_error("Failed to allocate trampoline memory")
	}

	// ----------------------------------------------------
	// 2. Generate stub for SendPacket
	// ----------------------------------------------------
	send_stub_addr := cast(uintptr)win.VirtualAlloc(
		nil,
		64,
		win.MEM_COMMIT | win.MEM_RESERVE,
		win.PAGE_EXECUTE_READWRITE,
	)

	if send_stub_addr != 0 {
		s := cast([^]byte)send_stub_addr
		stub_bytes := []byte {
			0x55, // push ebp
			0x89,
			0xE5, // mov ebp, esp
			0x8B,
			0x45,
			0x08, // mov eax, [ebp+8]   (tnt_client)
			0x8B,
			0x00, // mov eax, [eax]
			0x8B,
			0x00, // mov eax, [eax]
			0x8B,
			0x00, // mov eax, [eax]
			0x8B,
			0x55,
			0x0C, // mov edx, [ebp+12]  (packet)
			0x8B,
			0x4D,
			0x10, // mov ecx, [ebp+16]  (send_addy)
			0xFF,
			0xD1, // call ecx
			0x89,
			0xEC, // mov esp, ebp
			0x5D, // pop ebp
			0xC3, // ret
		}
		copy(s[:len(stub_bytes)], stub_bytes)
		send_packet_proc = cast(proc "c" (uintptr, cstring, uintptr))rawptr(send_stub_addr)
	} else {
		log_error("Failed to allocate send_stub memory")
	}

	// ----------------------------------------------------
	// 3. Generate stub for RecvPacket
	// ----------------------------------------------------
	recv_stub_addr := cast(uintptr)win.VirtualAlloc(
		nil,
		64,
		win.MEM_COMMIT | win.MEM_RESERVE,
		win.PAGE_EXECUTE_READWRITE,
	)

	if recv_stub_addr != 0 {
		r := cast([^]byte)recv_stub_addr
		// void RecvPacket(const QString &i_sString)
		// mov eax, dword ptr ds : [dwPacketClass] -> in Odin we pass this as arg1 (ebp+8)
		// mov eax, dword ptr ds : [eax]
		// mov eax, dword ptr ds : [eax]
		// mov eax, dword ptr ds : [eax + 34h]
		// mov edx, szPacket -> arg2 (ebp+12)
		// call dwPacketCall -> arg3 (ebp+16)
		stub_bytes_recv := []byte {
			0x55,             // push ebp
			0x89, 0xE5,       // mov ebp, esp
			0x8B, 0x45, 0x08, // mov eax, [ebp+8]   (packet_class_ptr)
			0x8B, 0x00,       // mov eax, [eax]
			0x8B, 0x00,       // mov eax, [eax]
			0x8B, 0x40, 0x34, // mov eax, [eax+0x34]
			0x8B, 0x55, 0x0C, // mov edx, [ebp+12]  (packet)
			0x8B, 0x4D, 0x10, // mov ecx, [ebp+16]  (recv_call)
			0xFF, 0xD1,       // call ecx
			0x89, 0xEC,       // mov esp, ebp
			0x5D,             // pop ebp
			0xC3,             // ret
		}
		copy(r[:len(stub_bytes_recv)], stub_bytes_recv)
		recv_packet_proc = cast(proc "c" (uintptr, cstring, uintptr))rawptr(recv_stub_addr)
	} else {
		log_error("Failed to allocate recv_stub memory")
	}

	// ----------------------------------------------------
	// 4. Generate trampoline for CustomSend
	// ----------------------------------------------------
	sendTrampoline_addr = cast(uintptr)win.VirtualAlloc(
		nil,
		128,
		win.MEM_COMMIT | win.MEM_RESERVE,
		win.PAGE_EXECUTE_READWRITE,
	)

	if sendTrampoline_addr != 0 {
		t := cast([^]byte)sendTrampoline_addr
		idx: uintptr = 0

		t[idx] = 0x60; idx += 1 // pushad
		t[idx] = 0x9C; idx += 1 // pushfd
		t[idx] = 0x52; idx += 1 // push edx (where sent packet string pointer is stored)

		// call odin_custom_send
		t[idx] = 0xE8; idx += 1
		offset1 := u32(cast(uintptr)rawptr(odin_custom_send) - (sendTrampoline_addr + idx + 4))
		(cast(^u32)(&t[idx]))^ = offset1
		idx += 4

		// add esp, 4
		t[idx] = 0x83; idx += 1
		t[idx] = 0xC4; idx += 1
		t[idx] = 0x04; idx += 1

		t[idx] = 0x9D; idx += 1 // popfd
		t[idx] = 0x61; idx += 1 // popad

		// save original bytes for unhook
		copy(sendOriginalBytes[:HOOK_SIZE_SEND], (cast([^]byte)SendAddy)[:HOOK_SIZE_SEND])

		// execute original 5 bytes
		copy((cast([^]byte)(&t[idx]))[:HOOK_SIZE_SEND], (cast([^]byte)SendAddy)[:HOOK_SIZE_SEND])
		idx += HOOK_SIZE_SEND

		// jmp back
		t[idx] = 0xE9; idx += 1
		jmpBackSend := SendAddy + HOOK_SIZE_SEND
		offset2 := u32(jmpBackSend - (sendTrampoline_addr + idx + 4))
		(cast(^u32)(&t[idx]))^ = offset2
		idx += 4
	} else {
		log_error("Failed to allocate send trampoline memory")
	}
}

hook_recv :: proc() {
	if trampoline_addr == 0 {return}

	oldProtect: win.DWORD
	win.VirtualProtect(
		cast(win.LPVOID)RecvHookAddy,
		HOOK_SIZE,
		win.PAGE_EXECUTE_READWRITE,
		&oldProtect,
	)

	dst := cast([^]byte)RecvHookAddy
	dst[0] = 0xE9 // jmp
	offset := u32(trampoline_addr - (RecvHookAddy + 5))
	(cast(^u32)(&dst[1]))^ = offset

	win.VirtualProtect(cast(win.LPVOID)RecvHookAddy, HOOK_SIZE, oldProtect, &oldProtect)
}

unhook_recv :: proc() {
	if trampoline_addr == 0 {return}

	oldProtect: win.DWORD
	win.VirtualProtect(
		cast(win.LPVOID)RecvHookAddy,
		HOOK_SIZE,
		win.PAGE_EXECUTE_READWRITE,
		&oldProtect,
	)

	copy((cast([^]byte)RecvHookAddy)[:HOOK_SIZE], originalBytes[:HOOK_SIZE])

	win.VirtualProtect(cast(win.LPVOID)RecvHookAddy, HOOK_SIZE, oldProtect, &oldProtect)
}

hook_send :: proc() {
	if sendTrampoline_addr == 0 {return}

	oldProtect: win.DWORD
	win.VirtualProtect(
		cast(win.LPVOID)SendAddy,
		HOOK_SIZE_SEND,
		win.PAGE_EXECUTE_READWRITE,
		&oldProtect,
	)

	dst := cast([^]byte)SendAddy
	dst[0] = 0xE9 // jmp
	offset := u32(sendTrampoline_addr - (SendAddy + 5))
	(cast(^u32)(&dst[1]))^ = offset
	dst[5] = 0x90 // nop for the 6th byte

	win.VirtualProtect(cast(win.LPVOID)SendAddy, HOOK_SIZE_SEND, oldProtect, &oldProtect)
}

unhook_send :: proc() {
	if sendTrampoline_addr == 0 {return}

	oldProtect: win.DWORD
	win.VirtualProtect(
		cast(win.LPVOID)SendAddy,
		HOOK_SIZE_SEND,
		win.PAGE_EXECUTE_READWRITE,
		&oldProtect,
	)

	copy((cast([^]byte)SendAddy)[:HOOK_SIZE_SEND], sendOriginalBytes[:HOOK_SIZE_SEND])

	win.VirtualProtect(cast(win.LPVOID)SendAddy, HOOK_SIZE_SEND, oldProtect, &oldProtect)
}

// Emulates NostaleStringA
send_packet :: proc(szPacket: string) {
	if send_packet_proc == nil || TNTClient == 0 || SendAddy == 0 {
		return
	}

	total_len := len(szPacket) + 8 + 1
	buf, alloc_err := mem.alloc(total_len)
	if alloc_err != nil {
		log_error("allocation failed in send_packet_internal")
		return
	}
	defer mem.free(buf)

	base := cast(uintptr)buf
	(cast(^u32)base)^ = 1 // RefCount
	(cast(^u32)(base + 4))^ = u32(len(szPacket)) // Length

	str_data := cast([^]u8)(base + 8)
	copy(str_data[:len(szPacket)], transmute([]u8)szPacket)
	str_data[len(szPacket)] = 0 // null terminator

	packet_cstr := cast(cstring)&str_data[0]
	// call the dynamic assembly stub using 'c' calling convention
	send_packet_proc(TNTClient, packet_cstr, SendAddy)
}

// Emulates NostaleStringA for Receive Packet
recv_packet_proc: proc "c" (packet_class_ptr: uintptr, packet: cstring, recv_call: uintptr)

recv_packet :: proc(szPacket: string) {
	if recv_packet_proc == nil || global_addrs.PacketClassPointer == 0 || global_addrs.RecvPacketCall == 0 {
		return
	}

	// We construct a fully compliant Delphi string with RefCount and Length.
	// AddressFunctions.cpp's CNosString had `std::size_t m_nLength` right before `char m_szPacket[5192]`.
	total_len := len(szPacket) + 8 + 1
	buf, alloc_err := mem.alloc(total_len)
	if alloc_err != nil {
		log_error("allocation failed in recv_packet")
		return
	}
	defer mem.free(buf)
	
	base := cast(uintptr)buf
	(cast(^u32)base)^ = 1               // RefCount
	(cast(^u32)(base + 4))^ = u32(len(szPacket)) // Length

	str_data := cast([^]u8)(base + 8)
	copy(str_data[:len(szPacket)], transmute([]u8)szPacket)
	str_data[len(szPacket)] = 0

	packet_cstr := cast(cstring)&str_data[0]
	recv_packet_proc(global_addrs.PacketClassPointer, packet_cstr, global_addrs.RecvPacketCall)
}

