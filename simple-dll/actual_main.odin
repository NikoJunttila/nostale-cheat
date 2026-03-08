#+build windows
package payload

import "core:fmt"
import "core:strings"
import "core:time"

// LPTHREAD_START_ROUTINE :: #type proc "stdcall" (parameter: rawptr) -> u32
global_addrs: packetlogger_addrs
packet_queue: SafeQueue
playerID: i32
playerSP: u8

actual_main :: proc() {
	iteration := 0
	log_info("payload main entered")
	modinfo := getModuleInfo()
	id, ok := get_player_id_internal(cast(^u8)modinfo.lpBaseOfDll, u32(modinfo.SizeOfImage))
	if ok {
		log_info(fmt.aprintf("player id: %d", id^))
		playerID = id^
	} else {
		log_info("failed to get id")
	}
	sp, ok2 := get_player_sp_internal(cast(^u8)modinfo.lpBaseOfDll, u32(modinfo.SizeOfImage))
	if ok2 {
		log_info(fmt.aprintf("player level: %d", sp^))
		playerSP = sp^
	} else {
		log_info("failed to get sp level")
	}

	ok3 := get_packetlogger_addrs(cast(^u8)modinfo.lpBaseOfDll, u32(modinfo.SizeOfImage))
	if ok3 {
		init_packetlogger(&packet_queue)
		hook_recv()
		log_info("packetlogger hooked")
	} else {
		log_warn("failed to get packetlogger addresses")
	}

	for {
		// Fetch packets from queue
		for !empty(&packet_queue) {
			packet, q_ok := front(&packet_queue)
			if q_ok {
				if strings.contains(packet, "u_s") {
					log_info(fmt.aprintf("RECV: %s", packet))
				}
			}
			pop(&packet_queue)
		}

		time.sleep(100 * time.Millisecond)
		iteration += 1
		if iteration % 50 == 0 {
			log_info("revealing map with 0 (recv)")
			recv_packet("tcrank 1") // this should send a client side packet that reveals map.
			// log_info("revealing map (recv)")
			s_packet := fmt.aprintf("u_s %d 1 %d", 10, playerID)
			log_info(fmt.aprintf("sending packet: %s", s_packet))
			send_packet(s_packet)
		}
	}
}
