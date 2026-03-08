package payload

import "core:time"

// LPTHREAD_START_ROUTINE :: #type proc "stdcall" (parameter: rawptr) -> u32

actual_main :: proc() {
	iteration := 0
	log_info("payload main entered")
	for {
		log_info("payload heartbeat")
		time.sleep(1000 * time.Millisecond)
		iteration += 1
		if iteration % 10 == 0 {
			log_warn("payload still alive")
		}
	}
}
