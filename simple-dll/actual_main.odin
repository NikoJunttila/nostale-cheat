#+build windows
package payload

import "core:fmt"
import "core:strings"
import win "core:sys/windows"
import "core:time"

global_addrs: packetlogger_addrs
packet_queue: SafeQueue
send_queue: SafeQueue

f5_was_down := false
f6_was_down := false
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

	is_down = (u16(win.GetAsyncKeyState(win.VK_F6)) & 0x8000) != 0
	if is_down && !f6_was_down {
		if bot.mode == .DPSCheck {
			state := &bot.state.(DPSCheckState)
			switch state.mode {
			case .IC:
				state.mode = .ASGOBAS
				log_info("dps state: ASGOBAS")
			case .ASGOBAS:
				state.mode = .RAID
				log_info("dps state: RAID")
			case .RAID:
				state.mode = .IC
				log_info("dps state: IC")
			}
		} else {
			bot.mode = .DPSCheck
			update_state()
			log_info("[F6] activated dps mode")
		}
	}
	f6_was_down = is_down
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
						words := strings.split(packet, " ")
						handle_packet(words)
						delete(words) //might cause errors? will cause memory leak if not cleaned up?
					}
				}
			}
			pop(&packet_queue)
		}

		// Fetch sent packets from queue
		for !empty(&send_queue) {
			packet, q_ok := front(&send_queue)
			if q_ok {
				// Filter spammy packets
				is_spam := false
				for p in spam_packets {
					if strings.has_prefix(packet, p) {
						is_spam = true
						break
					}
				}
				if !is_spam do log_sent_packet(packet)
			}
			pop(&send_queue)
		}

		bot_tick()
		handle_hotkeys()

		time.sleep(25 * time.Millisecond)
		iteration += 1
		if iteration % 1000 == 0 {
			check_afk()
			// log_message := fmt.aprintf(
			// 	"p que: %d, %d skill_que, %d s_que",
			// 	len(packet_queue.queue),
			// 	len(bot.skill_que),
			// 	len(send_queue.queue),
			// )
			// log_info(log_message)
			// delete(log_message)
			iteration = 1
		}
	}
}
