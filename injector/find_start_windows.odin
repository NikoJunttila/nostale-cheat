package injector

import "core:fmt"
import "core:strings"
import "core:sys/windows"


// find_process_by_name searches for a running process by its executable name
// Parameters:
//   process_name: The name of the process to find (e.g., "notepad.exe") Returns:
//   bool: true if the process was found, false otherwise
//   u32: Process ID (PID) of the found process (0 if not found)
find_all_processes_by_name :: proc(process_name: string) -> (pids: [dynamic]u32, ok: bool) {
	pids = make([dynamic]u32)
	ok = false
	// Create a snapshot of all processes currently running in the system
	// TH32CS_SNAPPROCESS flag specifies that we want process information
	// 0 is passed as the second parameter because it's ignored when capturing all processes
	snapshot := windows.CreateToolhelp32Snapshot(windows.TH32CS_SNAPPROCESS, 0)

	// Check if the snapshot creation failed
	if snapshot == windows.INVALID_HANDLE_VALUE {
		fmt.println("Failed to create process snapshot")
		return
	}

	// Ensure the snapshot handle is closed when this function exits
	// defer guarantees this runs at the end of the function scope regardless of how it exits
	defer windows.CloseHandle(snapshot)

	// Declare a process entry structure to store information about each process
	// Using PROCESSENTRY32W (W suffix) for Unicode/wide character support
	pe: windows.PROCESSENTRY32W

	// Set the size field of the structure - required before calling Process32FirstW
	pe.dwSize = size_of(windows.PROCESSENTRY32W)

	// Get the first process in the snapshot
	// This initializes 'pe' with the first process's information
	if !windows.Process32FirstW(snapshot, &pe) {
		fmt.println("Failed to get first process")
		return
	}

	// Iterate through all processes in the snapshot
	for {
		// Convert the process executable name from UTF-16 (wide character) format to UTF-8
		// pe.szExeFile[:] gets the WCHAR array as a slice to pass to the conversion function
		current_name, _ := windows.utf16_to_utf8(pe.szExeFile[:])

		// Compare the current process name with the target process name (case-insensitive)
		// strings.to_lower converts both names to lowercase before comparison
		// strings.compare returns 0 if the strings match
		if strings.compare(strings.to_lower(current_name), strings.to_lower(process_name)) == 0 {
			// Process found - print details and return success with the process ID
			fmt.printf("Found process: %s (PID: %d)\n", current_name, pe.th32ProcessID)
			append(&pids, pe.th32ProcessID)
		}

		// Move to the next process in the snapshot
		// If there are no more processes, Process32NextW returns false
		if !windows.Process32NextW(snapshot, &pe) {
			break // Exit the loop when no more processes are available
		}
	}
	if len(pids) > 0 {
		ok = true
		return
	}
	return
}
