#+build windows
package payload

import "core:fmt"
import "core:slice"
import "core:strings"
// import "core:thread"
import "core:time"

// LPTHREAD_START_ROUTINE :: #type proc "stdcall" (parameter: rawptr) -> u32
global_addrs: packetlogger_addrs
packet_queue: SafeQueue

iteration := 0
actual_main :: proc() {
	log_info("payload main entered")

	init_bot()
	// thread.create_and_start(gui.start_gui)
	recv_packet("tcrank 1")
	for {
		// Fetch packets from queue
		for !empty(&packet_queue) {
			packet, q_ok := front(&packet_queue)
			if q_ok {
				words := strings.split(packet, " ")
				if slice.contains(important_packets, words[0]) {
					handle_fishing_packet(words)
				}
				//delete(words) //might cause errors? will cause memory leak if not cleaned up?
			}
			pop(&packet_queue)
		}

		bot_tick()

		time.sleep(50 * time.Millisecond)
		iteration += 1
		if iteration % 1000 == 0 {
			log_message := fmt.aprintf(
				"p que: %d, %d que",
				len(packet_queue.queue),
				len(bot.skill_que),
			)
			log_info(log_message)
			delete(log_message)
			iteration = 1
		}
	}
}
