package payload

import "core:fmt"
import "core:thread"

main :: proc() {
	// if I dont have when I get compiler errors about u16
	when ODIN_OS == .Windows {
		setup_console() // does not actually log anything at the moment. problems with different threads?
		thread.create_and_start(actual_main)
	}
	fmt.println("hellope")
}
