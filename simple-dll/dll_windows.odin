package payload

import "core:fmt"
import "core:time"

// LPTHREAD_START_ROUTINE :: #type proc "stdcall" (parameter: rawptr) -> u32

actual_main :: proc() {
	iteration := 0
	log_info("payload main entered")
	modinfo := getModuleInfo()
	id, ok := get_player_id_internal(cast(^u8)modinfo.lpBaseOfDll, u32(modinfo.SizeOfImage))
	if ok {
		log_info(fmt.aprintf("player id: %d", id^))
	} else {
		log_info("failed to get id")
	}
	sp, ok2 := get_player_sp_internal(cast(^u8)modinfo.lpBaseOfDll, u32(modinfo.SizeOfImage))
	if ok2 {
		log_info(fmt.aprintf("player level: %d", sp^))
	} else {
		log_info("failed to get sp level")
	}
	for {
		fmt.println("payload heartbeat")
		time.sleep(5000 * time.Millisecond)
		iteration += 1
		if iteration % 10 == 0 {
			log_warn("payload still alive")
		} else {
			log_info("payload heartbeat")

		}
	}
}
