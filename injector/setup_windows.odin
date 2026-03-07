package injector

import "core:fmt"

setup_and_inject :: proc(proc_name, dll_path: string) -> bool {
	fmt.printfln("[INFO] Attempting to inject DLL '%s' into process '%s'", dll_path, proc_name)
	if !windows_file_exists(dll_path) {
		fmt.printf("[ERROR] DLL not found: %s\n", dll_path)
		return false
	}

	fullPath, ok := windows_get_full_path(dll_path)
	if !ok {
		fmt.println("[ERROR] Error getting full path for dll")
		return false
	}

	pids, found := find_all_processes_by_name(proc_name)

	if found {
		for pid in pids {
			fmt.printf(
				"[INFO] Attempting to inject DLL '%s' into process '%s' (PID: %d)\n",
				dll_path,
				proc_name,
				pid,
			)
			main_game := is_main_game_process(pid)
			if main_game {
				ok := inject_dll(pid, dll_path)
				break
			}
		}
	} else {
		fmt.printf("[ERROR] Target process '%s' not found\n", proc_name)
		return false
	}
	return true
}
