package main

import "core:fmt"
import "core:os"
import "core:time"

// tEvent: time 1773913394.174867, type 4 (EV_MSC), code 4 (MSC_SCAN), value 70017
// Event: time 1773913394.174867, type 1 (EV_KEY), code 20 (KEY_T), value 0

// ydotool key 20:1 20:0
main :: proc() {
	desc := os.Process_Desc {
		command = []string{"ydotool", "key", "20:1", "20:0"}, // first is push and then release
	}
	time.sleep(time.Second)
	for {
		state, stdin, stdout, err := os.process_exec(desc, context.allocator)
		if err != nil {
			fmt.println(err)
			os.exit(1)
		}
		time.sleep(300 * time.Millisecond)
	}
}
