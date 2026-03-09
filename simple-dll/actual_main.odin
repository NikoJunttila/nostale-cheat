#+build windows
package payload

import "core:strings"
// import "core:thread"
import "core:time"

// LPTHREAD_START_ROUTINE :: #type proc "stdcall" (parameter: rawptr) -> u32
global_addrs: packetlogger_addrs
packet_queue: SafeQueue

actual_main :: proc() {
	iteration := 0
	log_info("payload main entered")

	bot := init_bot()
	// thread.create_and_start(gui.start_gui)
	recv_packet("tcrank 1")
	for {
		// Fetch packets from queue
		for !empty(&packet_queue) {
			packet, q_ok := front(&packet_queue)
			if q_ok {
				log_info(packet)
				words := strings.split(packet, " ")
				handle_fishing_packet(&bot, words)
			}
			pop(&packet_queue)
		}

		time.sleep(100 * time.Millisecond)
		iteration += 1
		if iteration % 50 == 0 {
			log_info("heartbeat")
		}
	}
}
