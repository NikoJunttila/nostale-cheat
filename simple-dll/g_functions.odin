#+build windows
package payload

// g_functions.odin
//
// Minimal reproduction of the C++ CallFunction.c pattern.
//
// Odin cannot natively express the Delphi "register" calling convention
// used by the game (EAX=this, EDX=arg1, CX/ECX=arg2).  Like the existing
// packetlogger.odin stubs, we use VirtualAlloc to create small executable
// shellcode thunks that translate from cdecl (what Odin calls) into the
// game's custom convention, then call the AOB-scanned function address.
//
// Register conventions reverse-engineered from CallFunction.c:
//
//   MoveTo(waypoint u32)
//       PUSH 1  ;  XOR ECX, ECX  ;  MOV EDX, waypoint
//       MOV EAX, [lpvMoveThis]  ;  MOV EAX, [EAX]  ;  CALL lpvMove
//
//   AttackMonster(monster u32, skill i16)
//       MOV CX,  skill  ;  MOV EDX, monster
//       MOV EAX, [lpvAttackThis]  ;  MOV EAX, [EAX]  ;  CALL lpvAttack
//
//   Collect(item u32)
//       MOV EAX, [lpvCollectThis]  ;  MOV EAX, [EAX]
//       MOV ECX, characterPointer  ;  MOV EDX, [ECX]
//       MOV ESI, item  ;  MOV EDX, ESI  ;  CALL lpvCollect

import "core:fmt"
import win "core:sys/windows"

// ---------------------------------------------------------------------------
// AOB patterns (verbatim from CallFunction.c)
// ---------------------------------------------------------------------------

ATTACK_PATTERN     :: []byte{0x6A, 0x00, 0x6A, 0x00, 0x6A, 0x00, 0xE8, 0x00, 0x00, 0x00, 0x00, 0xC3, 0x55}
ATTACK_MASK        :: "x?x?x?x????xx"

MOVE_PATTERN       :: []byte{0x55, 0x8B, 0xEC, 0x83, 0xC4, 0x00, 0x53, 0x56, 0x57, 0x66, 0x89, 0x00, 0x00, 0x89, 0x55}
MOVE_MASK          :: "xxxxx?xxxxx??xx"

COLLECT_PATTERN    :: []byte{
	0x55, 0x8B, 0xEC, 0x6A, 0x00, 0x6A, 0x00, 0x6A, 0x00, 0x6A, 0x00,
	0x53, 0x56, 0x8B, 0xD9, 0x8B, 0xF2, 0x33, 0xC0, 0x55, 0x68, 0x00,
	0x00, 0x00, 0x00, 0x64, 0xFF, 0x00, 0x64, 0x89, 0x00, 0xA1,
}
COLLECT_MASK       :: "xxxx?x?x?x?xxxxxxxxxx????xx?xx?x"

ATTACK_RUN_PATTERN :: []byte{0x55, 0x8B, 0xEC, 0x51, 0x53, 0x56, 0x57, 0x88, 0x4D, 0x00, 0x8B, 0xF2, 0x8B, 0xF8}
ATTACK_RUN_MASK    :: "xxxxxxxxx?xxxx"

// ---------------------------------------------------------------------------
// Static this-pointers (offsets_reference.md §6)
// ---------------------------------------------------------------------------

ATTACK_THIS_ADDR  :: uintptr(0x008F4904)
MOVE_THIS_ADDR    :: uintptr(0x008F4904)
COLLECT_THIS_ADDR :: uintptr(0x00765EA8)
CHAR_PTR_ADDR     :: uintptr(0x00360E7C) // characterPointer global

// ---------------------------------------------------------------------------
// Proc types – all stubs are called with the standard cdecl "c" convention
// ---------------------------------------------------------------------------

Move_Proc        :: proc "c" (fn: uintptr, this_ptr: uintptr, waypoint: u32)
Attack_Proc      :: proc "c" (fn: uintptr, this_ptr: uintptr, monster: u32, skill: u32)
Collect_Proc     :: proc "c" (fn: uintptr, this_ptr: uintptr, char_ptr: u32, item: u32)
AttackRun_Proc   :: proc "c" (fn: uintptr, this_ptr: uintptr, monster: u32)

// ---------------------------------------------------------------------------
// Globals – filled by find_game_addresses() then build_stubs()
// ---------------------------------------------------------------------------

g_move_fn        : uintptr
g_attack_fn      : uintptr
g_attack_run_fn  : uintptr
g_collect_fn     : uintptr

g_move_stub       : Move_Proc
g_attack_stub     : Attack_Proc
g_collect_stub    : Collect_Proc
g_attack_run_stub : AttackRun_Proc

g_addrs_ready : bool

// ---------------------------------------------------------------------------
// alloc_stub – allocate a small RWX executable buffer and copy bytes into it
// ---------------------------------------------------------------------------

alloc_stub :: proc(code: []byte) -> uintptr {
	mem := win.VirtualAlloc(
		nil,
		uint(len(code)),
		win.MEM_COMMIT | win.MEM_RESERVE,
		win.PAGE_EXECUTE_READWRITE,
	)
	if mem == nil {
		log_error("VirtualAlloc failed for game stub")
		return 0
	}
	dst := cast([^]byte)mem
	for i in 0 ..< len(code) {
		dst[i] = code[i]
	}
	return cast(uintptr)mem
}

// patch_u32 – write a u32 into buf at offset (little-endian)
patch_u32 :: proc(buf: [^]byte, offset: int, val: u32) {
	buf[offset + 0] = u8(val & 0xFF)
	buf[offset + 1] = u8((val >> 8) & 0xFF)
	buf[offset + 2] = u8((val >> 16) & 0xFF)
	buf[offset + 3] = u8((val >> 24) & 0xFF)
}

// ---------------------------------------------------------------------------
// build_stubs – create one shellcode trampoline per game function.
//
// Each stub is a tiny cdecl function that:
//   1. Sets up the registers the game expects
//   2. CALLs the scanned game function
//   3. Returns to Odin normally
//
// We follow the same VirtualAlloc pattern as packetlogger.odin.
// ---------------------------------------------------------------------------

build_stubs :: proc() -> bool {
	ok := true

	// ----------------------------------------------------------------
	// 1.  MoveTo stub
	//
	// cdecl arguments (pushed by Odin, right-to-left):
	//   [ebp+8]  = fn        (game function address)
	//   [ebp+12] = this_ptr  (lpvMoveThis, already the raw address 0x8F4904)
	//   [ebp+16] = waypoint
	//
	// Game convention:
	//   PUSH 1       ; extra parameter the game reads from stack
	//   XOR ECX, ECX
	//   MOV EDX, waypoint
	//   MOV EAX, [this_ptr]   ; dereference
	//   MOV EAX, [EAX]
	//   CALL fn
	// ----------------------------------------------------------------
	move_code := []byte{
		0x55,             // push ebp
		0x89, 0xE5,       // mov ebp, esp
		0x6A, 0x01,       // push 1              (extra game param)
		0x33, 0xC9,       // xor ecx, ecx
		0x8B, 0x55, 0x10, // mov edx, [ebp+16]  (waypoint)
		0x8B, 0x45, 0x0C, // mov eax, [ebp+12]  (this_ptr)
		0x8B, 0x00,       // mov eax, [eax]      (dereference)
		0xFF, 0x55, 0x08, // call [ebp+8]        (fn)
		0x89, 0xEC,       // mov esp, ebp        (restore – balances our push 1)
		0x5D,             // pop ebp
		0xC3,             // ret
	}
	if addr := alloc_stub(move_code); addr != 0 {
		g_move_stub = cast(Move_Proc)rawptr(addr)
		fmt.println("[g_functions] move stub @", addr)
	} else {
		ok = false
	}

	// ----------------------------------------------------------------
	// 2.  AttackMonster stub
	//
	// cdecl arguments:
	//   [ebp+8]  = fn
	//   [ebp+12] = this_ptr
	//   [ebp+16] = monster
	//   [ebp+20] = skill   (passed as u32; game reads CX so low 16 bits only)
	//
	// Game convention:
	//   MOV CX,  skill      (CX = low word of ECX)
	//   MOV EDX, monster
	//   MOV EAX, [this_ptr]
	//   MOV EAX, [EAX]
	//   CALL fn
	// ----------------------------------------------------------------
	attack_code := []byte{
		0x55,             // push ebp
		0x89, 0xE5,       // mov ebp, esp
		0x8B, 0x4D, 0x14, // mov ecx, [ebp+20]  (skill, full 32-bit; game uses CX)
		0x8B, 0x55, 0x10, // mov edx, [ebp+16]  (monster)
		0x8B, 0x45, 0x0C, // mov eax, [ebp+12]  (this_ptr)
		0x8B, 0x00,       // mov eax, [eax]
		0xFF, 0x55, 0x08, // call [ebp+8]        (fn)
		0x5D,             // pop ebp
		0xC3,             // ret
	}
	if addr := alloc_stub(attack_code); addr != 0 {
		g_attack_stub = cast(Attack_Proc)rawptr(addr)
		fmt.println("[g_functions] attack stub @", addr)
	} else {
		ok = false
	}

	// ----------------------------------------------------------------
	// 3.  Collect stub
	//
	// cdecl arguments:
	//   [ebp+8]  = fn
	//   [ebp+12] = this_ptr   (lpvCollectThis, 0x765EA8)
	//   [ebp+16] = char_ptr   (already dereferenced ReadPointer result)
	//   [ebp+20] = item
	//
	// Game convention:
	//   MOV EAX, [this_ptr] ; MOV EAX, [EAX]
	//   MOV ECX, char_ptr
	//   MOV EDX, [ECX]
	//   MOV ESI, item ; MOV EDX, ESI
	//   CALL fn
	// ----------------------------------------------------------------
	collect_code := []byte{
		0x55,                   // push ebp
		0x89, 0xE5,             // mov ebp, esp
		0x56,                   // push esi          (save non-volatile)
		0x8B, 0x45, 0x0C,       // mov eax, [ebp+12] (this_ptr)
		0x8B, 0x00,             // mov eax, [eax]    (dereference)
		0x8B, 0x4D, 0x10,       // mov ecx, [ebp+16] (char_ptr)
		0x8B, 0x11,             // mov edx, [ecx]    (dereference char_ptr)
		0x8B, 0x75, 0x14,       // mov esi, [ebp+20] (item)
		0x89, 0xF2,             // mov edx, esi      (item -> edx, as in C++)
		0xFF, 0x55, 0x08,       // call [ebp+8]      (fn)
		0x5E,                   // pop esi
		0x5D,                   // pop ebp
		0xC3,                   // ret
	}
	if addr := alloc_stub(collect_code); addr != 0 {
		g_collect_stub = cast(Collect_Proc)rawptr(addr)
		fmt.println("[g_functions] collect stub @", addr)
	} else {
		ok = false
	}

	// ----------------------------------------------------------------
	// 4.  AttackRun stub
	//
	// cdecl arguments:
	//   [ebp+8]  = fn
	//   [ebp+12] = this_ptr
	//   [ebp+16] = monster
	//
	// Game convention (from C++):
	//   PUSH 1 ; MOV CL, 0 ; MOV EDX, monster
	//   MOV EAX, [this_ptr] ; MOV EAX, [EAX] ; CALL fn
	// ----------------------------------------------------------------
	attack_run_code := []byte{
		0x55,             // push ebp
		0x89, 0xE5,       // mov ebp, esp
		0x6A, 0x01,       // push 1
		0x33, 0xC9,       // xor ecx, ecx      (CL = 0)
		0x8B, 0x55, 0x10, // mov edx, [ebp+16] (monster)
		0x8B, 0x45, 0x0C, // mov eax, [ebp+12] (this_ptr)
		0x8B, 0x00,       // mov eax, [eax]
		0xFF, 0x55, 0x08, // call [ebp+8]      (fn)
		0x89, 0xEC,       // mov esp, ebp      (balance push 1)
		0x5D,             // pop ebp
		0xC3,             // ret
	}
	if addr := alloc_stub(attack_run_code); addr != 0 {
		g_attack_run_stub = cast(AttackRun_Proc)rawptr(addr)
		fmt.println("[g_functions] attack_run stub @", addr)
	} else {
		// AttackRun is optional for the minimal repro
		fmt.println("[g_functions] WARNING: attack_run stub alloc failed")
	}

	return ok
}

// ---------------------------------------------------------------------------
// find_game_addresses – AOB-scan the module image for each function.
// Call once from init_bot() / actual_main before using any wrapper.
// ---------------------------------------------------------------------------

find_game_addresses :: proc() -> bool {
	modinfo := getModuleInfo()
	base    := cast(^u8)(modinfo.lpBaseOfDll)
	size    := modinfo.SizeOfImage

	ok := true

	if addr, found := find_pattern_internal(base, size, ATTACK_PATTERN, ATTACK_MASK); found {
		g_attack_fn = addr
		fmt.println("[g_functions] Attack fn @", addr)
	} else {
		fmt.println("[g_functions] ERROR: Attack pattern not found")
		ok = false
	}

	if addr, found := find_pattern_internal(base, size, MOVE_PATTERN, MOVE_MASK); found {
		g_move_fn = addr
		fmt.println("[g_functions] Move fn @", addr)
	} else {
		fmt.println("[g_functions] ERROR: Move pattern not found")
		ok = false
	}

	if addr, found := find_pattern_internal(base, size, COLLECT_PATTERN, COLLECT_MASK); found {
		g_collect_fn = addr
		fmt.println("[g_functions] Collect fn @", addr)
	} else {
		fmt.println("[g_functions] ERROR: Collect pattern not found")
		ok = false
	}

	if addr, found := find_pattern_internal(base, size, ATTACK_RUN_PATTERN, ATTACK_RUN_MASK); found {
		g_attack_run_fn = addr
		fmt.println("[g_functions] AttackRun fn @", addr)
	} else {
		fmt.println("[g_functions] WARNING: AttackRun pattern not found (optional)")
	}

	if ok {
		ok = build_stubs()
	}

	g_addrs_ready = ok
	return ok
}

// ---------------------------------------------------------------------------
// Public wrappers – call these from bot logic
// ---------------------------------------------------------------------------

game_move_to :: proc(waypoint: u32) {
	if !g_addrs_ready || g_move_stub == nil { return }
	g_move_stub(g_move_fn, MOVE_THIS_ADDR, waypoint)
}

game_attack_monster :: proc(monster: u32, skill: i16) {
	if !g_addrs_ready || g_attack_stub == nil { return }
	g_attack_stub(g_attack_fn, ATTACK_THIS_ADDR, monster, u32(u16(skill)))
}

game_collect :: proc(item: u32) {
	if !g_addrs_ready || g_collect_stub == nil { return }

	// Replicate ReadPointer(0x360E7C, {0x0}): add image base then dereference
	modinfo    := getModuleInfo()
	image_base := uintptr(modinfo.lpBaseOfDll)
	char_ptr   := (cast(^u32)(image_base + CHAR_PTR_ADDR))^

	g_collect_stub(g_collect_fn, COLLECT_THIS_ADDR, char_ptr, item)
}

game_attack_run :: proc(monster: u32) {
	if !g_addrs_ready || g_attack_run_stub == nil { return }
	g_attack_run_stub(g_attack_run_fn, ATTACK_THIS_ADDR, monster)
}
