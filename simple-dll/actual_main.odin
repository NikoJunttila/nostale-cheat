#+build windows
package payload

import "core:strings"
import win "core:sys/windows"
import "core:thread"
import "core:time"

global_addrs: packetlogger_addrs
packet_queue: SafeQueue
send_queue: SafeQueue

f8_was_down := false
iteration := 0

handle_hotkeys :: proc() {
	is_down := (u16(win.GetAsyncKeyState(win.VK_F8)) & 0x8000) != 0
	if is_down && !f8_was_down {
		asgobas_timer()
		// sp_transform := "sl 1"
		// send_packet(sp_transform)
	}
	f8_was_down = is_down
}

actual_main :: proc() {
	init_bot()
	thread.create_and_start(start_gui)
	asgobas_timer()
	for {

		packet_queue_tick()
		sent_packet_que_tick()
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

packet_queue_tick :: proc() {
	// Fetch packets from queue
	for !empty(&packet_queue) {
		packet, q_ok := front(&packet_queue)
		if q_ok {
			for p in important_packets {
				if strings.contains(packet, p) {
					cleaned_p := strings.trim_right(packet, "\n")
					words := strings.split(cleaned_p, " ")
					handle_packet(words)
					delete(words) //might cause errors? will cause memory leak if not cleaned up?
					break
				}
			}
		}
		pop(&packet_queue)
	}
}

sent_packet_que_tick :: proc() {
	// Fetch sent packets from queue
	for !empty(&send_queue) {
		packet, q_ok := front(&send_queue)
		if q_ok {
			if bot.mode == .COOKING {
				cleaned_p := strings.trim_right(packet, "\n")
				words := strings.split(cleaned_p, " ")
				handle_sent_cooking_packet(words)
				delete(words)
			}
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
}
