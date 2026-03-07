package injector

import "core:fmt"
import os "core:os/old"

main :: proc() {
	when ODIN_OS == .Windows {

		// Get process name and DLL path from command-line arguments or use defaults
		process_name := "exampletotarget.exe" // Default process
		//find full path for dll
		dll_path := "simple.dll" // Default DLL path
		if ok := os.exists(dll_path); !ok {
			fmt.printfln("dll not found")
			os.exit(1)
		}
		fullPath, ok := windows_get_full_path(dll_path)
		if !ok {
			fmt.println("[ERROR] Error getting full path for dll")
			return
		} else {
			fmt.println("Full path: ", fullPath)
		}

		found, pid := find_process_by_name(process_name)

		if found {
			fmt.printf(
				"[INFO] Attempting to inject DLL '%s' into process '%s' (PID: %d)\n",
				fullPath,
				process_name,
				pid,
			)
			inject_dll(pid, fullPath, true)
			//inject(pid,fullPath)
		} else {
			fmt.printf("[ERROR] Target process '%s' not found\n", process_name)
			os.exit(1)
		}
		// load_local_dll(dll_path)
		fmt.println("[INFO] DLL Injector completed")
	}
}
