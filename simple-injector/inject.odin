package injector

import "core:fmt"
import "core:sys/windows"

LPTHREAD_START_ROUTINE :: #type proc "stdcall" (parameter: rawptr) -> u32

global_dll_base: windows.DWORD
offset: uintptr
// inject_dll injects a DLL into a target process
// Parameters:
//   pid: Process ID of the target process
//   dll_path: Full path to the DLL file to inject
//   verbose: Whether to print verbose logging information
// Returns:
//   bool: true if injection was successful, false otherwise
inject_dll :: proc(pid: u32, dll_path: string, verbose: bool = false) -> bool {
	if verbose {
		fmt.printf("[INFO] Starting DLL injection process for PID %d\n", pid)
		fmt.printf("[INFO] Target DLL: '%s'\n", dll_path)
	}
	defer free_all(context.temp_allocator)

	// Validate input parameters
	if pid == 0 {
		fmt.println("[ERROR] Invalid process ID (0)")
		return false
	}

	// Open the target process with required access rights
	process_handle := windows.OpenProcess(
		windows.PROCESS_CREATE_THREAD |
		windows.PROCESS_QUERY_INFORMATION |
		windows.PROCESS_VM_OPERATION |
		windows.PROCESS_VM_WRITE |
		windows.PROCESS_VM_READ,
		false,
		pid,
	)
	fmt.println("hProc ", process_handle)

	if process_handle == nil {
		error_code := windows.GetLastError()
		fmt.printf("[ERROR] Failed to open process (PID: %d). Error code: %d\n", pid, error_code)
		// Provide more specific error information based on common error codes
		switch error_code {
		case 5:
			fmt.println("[DETAIL] Access denied. Try running with administrator privileges.")
		case 87:
			fmt.println("[DETAIL] Invalid parameter. The specified process ID may not exist.")
		case:
			fmt.println("[DETAIL] Unknown error occurred while opening the process.")
		}
		return false
	}
	defer windows.CloseHandle(process_handle)

	if verbose {
		fmt.println("[INFO] Successfully opened target process")
	}

	// Convert DLL path to UTF-16 for Windows API
	dll_path_utf16 := windows.utf8_to_utf16(dll_path)
	dll_path_bytes := len(dll_path_utf16) * size_of(windows.WCHAR)

	// Allocate memory in the target process for the DLL path
	remote_memory := windows.VirtualAllocEx(
		process_handle,
		nil,
		cast(uint)dll_path_bytes,
		windows.MEM_COMMIT | windows.MEM_RESERVE,
		windows.PAGE_READWRITE,
	)

	if remote_memory == nil {
		error_code := windows.GetLastError()
		fmt.printf(
			"[ERROR] Failed to allocate memory in the target process. Error code: %d\n",
			error_code,
		)
		return false
	}
	defer windows.VirtualFreeEx(process_handle, remote_memory, 0, windows.MEM_RELEASE)

	if verbose {
		fmt.printf("[INFO] Memory allocated at address: %v\n", remote_memory)
	}

	// Write the DLL path to the allocated memory
	bytes_written: uint
	write_result := windows.WriteProcessMemory(
		process_handle,
		remote_memory,
		&dll_path_utf16[0],
		cast(uint)dll_path_bytes,
		&bytes_written,
	)

	if !write_result {
		error_code := windows.GetLastError()
		fmt.printf(
			"[ERROR] Failed to write to target process memory. Error code: %d\n",
			error_code,
		)
		return false
	}

	if verbose {
		fmt.printf("[INFO] Successfully wrote %d bytes to target process memory\n", bytes_written)
	}

	// Get handle to kernel32.dll
	windows_string := windows.utf8_to_wstring("kernel32.dll")
	kernel32 := windows.LoadLibraryW(windows_string)
	if kernel32 == nil {
		error_code := windows.GetLastError()
		fmt.printf("[ERROR] Failed to get kernel32.dll handle. Error code: %d\n", error_code)
		return false
	}
	defer windows.FreeLibrary(kernel32)

	// Get the address of LoadLibraryW from kernel32.dll
	load_library_addr := windows.GetProcAddress(kernel32, "LoadLibraryW")
	if load_library_addr == nil {
		error_code := windows.GetLastError()
		fmt.printf("[ERROR] Failed to get LoadLibraryW address. Error code: %d\n", error_code)
		return false
	}

	thread_start_routine := cast(LPTHREAD_START_ROUTINE)load_library_addr

	if verbose {
		fmt.println("[INFO] Successfully obtained LoadLibraryW address")
	}

	// Create a remote thread that calls LoadLibraryW with the DLL path as argument
	thread_id: u32
	thread_handle := windows.CreateRemoteThread(
		process_handle,
		nil,
		0,
		thread_start_routine,
		remote_memory,
		0,
		&thread_id,
	)

	if thread_handle == nil {
		error_code := windows.GetLastError()
		fmt.printf("[ERROR] Failed to create remote thread. Error code: %d\n", error_code)
		return false
	}
	defer windows.CloseHandle(thread_handle)

	if verbose {
		fmt.printf("[INFO] Remote thread created with ID: %d\n", thread_id)
		fmt.println("[INFO] Handle: ", thread_handle)
		fmt.println("[INFO] Waiting for remote thread to complete...")
	}

	// Wait for the remote thread to complete with timeout
	wait_timeout := windows.DWORD(10000) // 10 seconds timeout
	wait_result := windows.WaitForSingleObject(thread_handle, wait_timeout)

	if wait_result == windows.WAIT_TIMEOUT {
		fmt.println("[ERROR] Remote thread execution timed out after 10 seconds")
		return false
	} else if wait_result != windows.WAIT_OBJECT_0 {
		error_code := windows.GetLastError()
		fmt.printf("[ERROR] Failed while waiting for remote thread. Error code: %d\n", error_code)
		return false
	}

	// Get the thread's exit code (should be the handle to the loaded DLL)
	if !windows.GetExitCodeThread(thread_handle, &global_dll_base) {
		error_code := windows.GetLastError()
		fmt.printf("[ERROR] Failed to get thread exit code. Error code: %d\n", error_code)
		return false
	}

	if global_dll_base == 0 {
		fmt.println("[ERROR] LoadLibraryW returned NULL. DLL may not have been loaded correctly.")
		return false
	}

	fmt.println("[SUCCESS] DLL injection completed successfully!")
	if verbose {
		fmt.printf("[INFO] LoadLibraryW returned module handle: %d\n", global_dll_base)
	}

	return true
}
lertFunc :: #type proc "stdcall" ()
