package injector

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:time"

setup_and_inject :: proc(proc_name, dll_path: string) -> bool {
	if ok := os.exists(dll_path); !ok {
		fmt.printfln("dll not found")
		os.exit(1)
	}
	fullPath, ok := filepath.abs(dll_path, context.temp_allocator)
	if !ok {
		fmt.println("[ERROR] Error getting full path for dll")
		return false
	} else {
		fmt.println("Full path: ", fullPath)
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
				time.sleep(1 * time.Second)
				port, portOK := find_listening_port_for_process(pid)
				if portOK {
					fmt.println("PID: ", pid)
					fmt.println("PORT: ", port)
				} else {
					fmt.println("failed to find port. add timeout?")
				}
				if !ok do break
			}
		}
	} else {
		fmt.printf("[ERROR] Target process '%s' not found\n", proc_name)
		os.exit(1)
	}
	return true
}
