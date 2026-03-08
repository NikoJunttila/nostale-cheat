#+build windows
package payload

import "core:fmt"
import win "core:sys/windows"

foreign import psapi "system:Psapi.lib"

// https://learn.microsoft.com/en-us/windows/win32/api/psapi/ns-psapi-moduleinfo
// typedef struct _MODULEINFO {
//   LPVOID lpBaseOfDll;
//   DWORD  SizeOfImage;
//   LPVOID EntryPoint;
// } MODULEINFO, *LPMODULEINFO;

MODULEINFO :: struct {
	lpBaseOfDll: win.LPVOID,
	SizeOfImage: win.DWORD,
	EntryPoint:  win.LPVOID,
}

@(default_calling_convention = "system")
foreign psapi {
	// https://learn.microsoft.com/en-us/windows/win32/api/psapi/nf-psapi-getmoduleinformation
	GetModuleInformation :: proc(hProcess: win.HANDLE, hModule: win.HMODULE, lpmodinfo: ^MODULEINFO, cb: win.DWORD) -> win.BOOL ---
}

getModuleInfo :: proc() -> MODULEINFO {
	modinfo := MODULEINFO{}
	hModule := win.GetModuleHandleA(nil)
	if hModule == nil {
		log_warn("failed to get module")
		return modinfo
	}
	ok := GetModuleInformation(win.GetCurrentProcess(), hModule, &modinfo, size_of(modinfo))
	if !ok {
		log_warn("failed to get module information")
	} else {
		log_info(fmt.aprintf("found module info stuff %d", modinfo.lpBaseOfDll))
	}
	return modinfo
}

find_pattern_internal :: proc(
	base: ^u8,
	size: u32,
	pattern: []byte,
	mask: string,
) -> (
	uintptr,
	bool,
) {
	pattern_len := len(mask)

	for i: u32 = 0; i < size - u32(pattern_len); i += 1 {
		found := true

		for j := 0; j < pattern_len; j += 1 {
			if mask[j] != '?' && pattern[j] != (cast([^]u8)base)[i + u32(j)] {
				found = false
				break
			}
		}

		if found {
			return uintptr(base) + uintptr(i), true
		}
	}

	return 0, false
}


get_player_id_internal :: proc(baseAddr: ^u8, baseSize: u32) -> (^i32, bool) {

	pattern1 := []byte {
		0xA1,
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0xFF,
		0xA1,
		0,
		0,
		0,
		0,
		0x83,
		0x38,
		0x00,
		0x76,
	}

	mask1 := "x????????xx????xx?x"

	pattern_addr, ok := find_pattern_internal(baseAddr, baseSize, pattern1, mask1)
	if !ok {
		fmt.println("player id pattern not found")
		return nil, false
	}

	ptr1 := (cast(^uintptr)(pattern_addr + 1))^
	ptr2 := (cast(^uintptr)(ptr1))^

	final_addr := ptr2 + 0x24

	return cast(^i32)(final_addr), true
}


get_player_sp_internal :: proc(baseAddr: ^u8, baseSize: u32) -> (^u8, bool) {

	pattern_sp := []byte {
		0xA1,
		0,
		0,
		0,
		0,
		0x8B,
		0,
		0x33,
		0xD2,
		0xE8,
		0,
		0,
		0,
		0,
		0xB3,
		0x01,
		0xA1,
		0,
		0,
		0,
		0,
		0x8B,
		0,
		0xE8,
		0,
		0,
		0,
		0,
		0x84,
		0xC0,
		0x74,
		0x21,
	}

	mask_sp := "x????xxxxx????xxx????xxx????xxxx"

	pattern_addr, ok := find_pattern_internal(baseAddr, baseSize, pattern_sp, mask_sp)

	if !ok {
		fmt.println("sp pattern not found")
		return nil, false
	}

	ptr1 := (cast(^uintptr)(pattern_addr + 1))^
	ptr2 := (cast(^uintptr)(ptr1))^
	ptr3 := (cast(^uintptr)(ptr2))^

	final_addr := ptr3 + 0x1B4

	return cast(^u8)(final_addr), true
}


// Call FindPattern for the 4 core signatures: RecvHook, SendHook, SendHook-Vendetta fallback, and PacketClassPointer.
// Store the resolved addresses in global variables or a map.

// void ReadPattern(const EAddress i_eAddress, const byte *i_abSignature, const char *i_szMask, const DWORD i_dwAdd = 0) {
// 	DWORD dwAddress = Memory::FindPattern(i_abSignature, i_szMask);
// 	if (dwAddress && i_dwAdd) {
// 		dwAddress = *reinterpret_cast<DWORD*>(dwAddress + i_dwAdd);
// 	}
