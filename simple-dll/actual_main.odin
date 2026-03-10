#+build windows
package payload

import "core:fmt"
import "core:slice"
import "core:strings"
import "core:time"
import win "core:sys/windows"

// LPTHREAD_START_ROUTINE :: #type proc "stdcall" (parameter: rawptr) -> u32
global_addrs: packetlogger_addrs
packet_queue: SafeQueue

f5_was_down := false
iteration   := 0

handle_hotkeys :: proc() {
	is_down := (u16(win.GetAsyncKeyState(win.VK_F5)) & 0x8000) != 0
	if is_down && !f5_was_down {
		if bot.mode == .PAUSED {
			bot.mode = .FISHING
			update_state()
			log_info("[F5] resumed fishing")
		} else {
			bot.mode = .PAUSED
			// flush any queued skills
			clear(&bot.skill_que)
			bot.currentDelay = 0
			log_info("[F5] paused")
		}
	}
	f5_was_down = is_down
}
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
		handle_hotkeys()

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
