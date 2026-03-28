package payload

import "core:fmt"
import "core:strings"
import "core:time"

CARP_SKEVER :: "2492"

handle_cooking_packet :: proc(words: []string) {
	switch words[0] {
	case EFF_S:
		cook_handle_eff_s(words)
	}
}

// broken. dont use
cook_handle_eff_s :: proc(words: []string) {
	if len(words) < 5 do return
	if words[1] != "1" do return
	if words[2] != bot.playerID do return
	if words[3] != "7790" do return
	if words[4] != "0" {
		log_info(fmt.tprintf("early return %s", strings.join(words, " ", context.temp_allocator)))
		return
	}
	log_info(fmt.tprintf("ok? %s", strings.join(words, " ", context.temp_allocator)))
	add_bot_skill_que(200, "3")
	packet := cooking_packet(CARP_SKEVER)
	add_packet_skill_que(5000, packet, true)
	// delete(packet) // where to delete this packet?
}

cooking_packet :: proc(food: string) -> string {
	return fmt.aprintf("u_s 2 1 %s %s 1 0", bot.playerID, food)
}

start_cooking :: proc() {
	log_info("starting cooking")
	packet := cooking_packet(CARP_SKEVER)
	add_packet_skill_que(0, packet, true)
}
