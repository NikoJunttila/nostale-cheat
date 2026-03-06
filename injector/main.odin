package injector

import "core:fmt"
import "core:log"

main :: proc() {
	// Get process name and DLL path from command-line arguments or use defaults
	process_name := "NostaleClientX.exe"
	//find full path for dll
	dll_path := "simple.dll" // Default DLL path
	when ODIN_OS == .Windows {
		ok := setup_and_inject(process_name, dll_path)
		if !ok {
			log.fatal("failed to inject")
		}
		fmt.println("[INFO] DLL Injector completed")
	} else {
		fmt.println("dummy! This is for windows")
	}
	// free_all(context.temp_allocator)//no need for this tbh, everything is freed anyways
}
