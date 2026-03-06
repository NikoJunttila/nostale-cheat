package injector

import "core:fmt"
import win "core:sys/windows"
import "core:c"

log :: fmt.println

inject :: proc(pid: win.DWORD, dll_path: string) {
	fmt.println(dll_path)
	hProc := win.OpenProcess(win.PROCESS_ALL_ACCESS, false, pid)
	if hProc == win.INVALID_HANDLE_VALUE {
		log("failed hproc", hProc)
		return
	}
	fmt.println("hProc", hProc)
	defer win.CloseHandle(hProc)
	allocMem := win.VirtualAllocEx(
		hProc,
		nil,
		win.MAX_PATH,
		win.MEM_COMMIT | win.MEM_RESERVE,
		win.PAGE_READWRITE,
	)
	fmt.println("alloc ", allocMem)
	if allocMem == nil {
		log("failed alloc: ", allocMem, " ", win.GetLastError())
		return
	}
	path := win.utf8_to_utf16(dll_path)
	dll_path_bytes := len(path) * size_of(win.WCHAR)
	ok := win.WriteProcessMemory(hProc, allocMem, &path[0], cast(uint)dll_path_bytes, nil)
	fmt.println("ok: ", ok)
	// Get handle to kernel32.dll
	windows_string := win.utf8_to_wstring("kernel32.dll")
	kernel32 := win.LoadLibraryW(windows_string)
	log("kernel32 ", kernel32)
	if kernel32 == nil {
		error_code := win.GetLastError()
		fmt.printf("[ERROR] Failed to get kernel32.dll handle. Error code: %d\n", error_code)
		return
	}
	defer win.FreeLibrary(kernel32)

	// Get the address of LoadLibraryW from kernel32.dll
	load_library_addr := win.GetProcAddress(kernel32, "LoadLibraryW")
	if load_library_addr == nil {
		error_code := win.GetLastError()
		fmt.printf("[ERROR] Failed to get LoadLibraryW address. Error code: %d\n", error_code)
		return
	}
	// thread_start_routine := cast(LPTHREAD_START_ROUTINE)win.LoadLibraryW //this does not work.
	thread_start_routine := cast(LPTHREAD_START_ROUTINE)load_library_addr
	hThread := win.CreateRemoteThread(hProc, nil, 0, thread_start_routine, allocMem, 0, nil)
	fmt.println("hThread ", hThread)
	if hThread == nil {
		log("failed hThread ", win.GetLastError())
	}
	fmt.println(win.GetLastError())
	defer win.CloseHandle(hThread)
}
