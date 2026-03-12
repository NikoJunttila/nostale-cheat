#+build windows
package payload

import "core:fmt"
import "core:strings"
import win "core:sys/windows"
import "core:time"

global_addrs: packetlogger_addrs
packet_queue: SafeQueue

f5_was_down := false
iteration := 0

handle_hotkeys :: proc() {
	is_down := (u16(win.GetAsyncKeyState(win.VK_F5)) & 0x8000) != 0
	if is_down && !f5_was_down {
		if bot.mode == .PAUSED {
			bot.mode = .FISHING
			update_state()
			log_info("[F5] resumed fishing")
		} else {
			bot_pause()
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
				for p in important_packets {
					if strings.contains(packet, p) {
						log_info(packet)
						words := strings.split(packet, " ")
						handle_packet(words)
						//delete(words) //might cause errors? will cause memory leak if not cleaned up?
					}
				}
			}
			pop(&packet_queue)
		}

		bot_tick()
		handle_hotkeys()

		time.sleep(50 * time.Millisecond)
		iteration += 1
		if iteration % 1000 == 0 {
			check_afk()
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
