package payload

// import "core:fmt"
// import win "core:sys/windows"

//cpp code
// playerID = (int*)(**(DWORD**)(Memory::FindPattern(
// 	(char*)"\xA1\x00\x00\x00\x00\x00\x00\x00\x00\xFF\xA1\x00\x00\x00\x00\x83\x38\x00\x76",
// 	(char*)"x????????xx????xx?x") + 1) + 0x24);
// Now dereference the pointer chain
// In C++: (int*)(**(DWORD**)(pattern_addr + 1) + 0x24)
// This means:
// 1. Read 4 bytes at (pattern_addr + 1) to get first pointer
// 2. Dereference that to get second pointer
// 3. Add 0x24 offset
// 4. Read the int value there
// pId := 43862 //player id should be something like this?
// External pattern scanning
// find_pattern_external :: proc(
// 	proc_handle: win.HANDLE,
// 	base: rawptr,
// 	size: u32,
// 	pattern: []byte,
// 	mask: string,
// ) -> (
// 	ptr: rawptr,
// 	ok: bool,
// ) {
// 	// Read entire module into memory
// 	module_bytes := read_memory(proc_handle, base, int(size)) or_return
// 	defer delete(module_bytes)
//
// 	pattern_len := len(mask)
// 	for i in 0 ..< (len(module_bytes) - pattern_len) {
// 		found := true
// 		for j in 0 ..< pattern_len {
// 			if mask[j] != '?' && pattern[j] != module_bytes[i + j] {
// 				found = false
// 				break
// 			}
// 		}
// 		if found {
// 			return rawptr(uintptr(base) + uintptr(i)), true
// 		}
// 	}
//
// 	return nil, false
// }
//
// //reads as much memory as we want and returns buffer we can do things with
// read_memory :: proc(proc_handle: win.HANDLE, address: rawptr, size: int) -> ([]byte, bool) {
// 	buffer := make([]byte, size)
// 	bytes_read: win.SIZE_T
//
// 	if !win.ReadProcessMemory(
// 		proc_handle,
// 		address,
// 		raw_data(buffer),
// 		win.SIZE_T(size),
// 		&bytes_read,
// 	) {
// 		delete(buffer)
// 		return nil, false
// 	}
//
// 	return buffer, true
// }
// // Helper to read a 32-bit pointer from memory, returns ptr, for 32bit games we need to read u32 and for 64bit games we need to read u64?
// read_pointer :: proc(proc_handle: win.HANDLE, address: rawptr) -> (ptr: rawptr, ok: bool) {
// 	ptr_value: u32 // Changed from uintptr to u32 for 32-bit
// 	bytes_read: win.SIZE_T
//
// 	if !win.ReadProcessMemory(
// 		proc_handle,
// 		address,
// 		&ptr_value,
// 		size_of(u32), // Changed to 4 bytes
// 		&bytes_read,
// 	) {
// 		return nil, false
// 	}
//
// 	return rawptr(uintptr(ptr_value)), true
// }
//
// // Helper to read an int32 from memory and returns actual value
// read_int32 :: proc(proc_handle: win.HANDLE, address: rawptr) -> (i32, bool) {
// 	value: i32
// 	bytes_read: win.SIZE_T
//
// 	if !win.ReadProcessMemory(proc_handle, address, &value, size_of(value), &bytes_read) {
// 		return 0, false
// 	}
//
// 	return value, true
// }
//
// // Helper to read an int32 from memory and returns actual value
// read_int8 :: proc(proc_handle: win.HANDLE, address: rawptr) -> (i8, bool) {
// 	value: i8
// 	bytes_read: win.SIZE_T
//
// 	if !win.ReadProcessMemory(proc_handle, address, &value, size_of(value), &bytes_read) {
// 		return 0, false
// 	}
// 	fmt.println("bytes_read: ", bytes_read)
//
// 	return value, true
// }
