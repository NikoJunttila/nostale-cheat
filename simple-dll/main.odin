package payload

import "core:fmt"
import "core:thread"

main :: proc() {
	// if I dont have when I get compiler errors about u16
	when ODIN_OS == .Windows {
		thread.create_and_start(actual_main)
	}
	fmt.println("hellope")
}
