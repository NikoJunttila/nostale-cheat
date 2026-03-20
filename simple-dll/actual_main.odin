#+build windows
package payload

import "core:strings"
import win "core:sys/windows"
import "core:time"

global_addrs: packetlogger_addrs
packet_queue: SafeQueue
send_queue: SafeQueue

f5_was_down := false
f6_was_down := false
f8_was_down := false
iteration := 0

handle_hotkeys :: proc() {
	is_down := (u16(win.GetAsyncKeyState(win.VK_F5)) & 0x8000) != 0
	if is_down && !f5_was_down {
		if bot.mode == .FISHING {
			bot_pause()
		} else {
			reset_skill_que()
			bot.mode = .FISHING
			update_state()
			log_info("[F5] resumed fishing")
		}
	}
	f5_was_down = is_down

	is_down = (u16(win.GetAsyncKeyState(win.VK_F6)) & 0x8000) != 0
	if is_down && !f6_was_down {
		reset_skill_que()
		if bot.mode == .DPSCheck {
			state := &bot.state.(DPSCheckState)
			switch state.mode {
			case .IC:
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
	is_down = (u16(win.GetAsyncKeyState(win.VK_F8)) & 0x8000) != 0
	if is_down && !f8_was_down {
		sp_transform := "sl 1"
		send_packet(sp_transform)
		log_info("should transform")
	}
	f8_was_down = is_down
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
			iteration = 1
			free_all(context.temp_allocator)
		}
	}
}
