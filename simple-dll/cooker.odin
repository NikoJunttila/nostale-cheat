//TODO way to make this better would to make the cooked item ID more dynamic so we start manually cooking and then start the loop with item id after getting first eff_s
// eff_s does not have item ID so we need to check for sent packets when we start cooking item
// while doing this we could also figure out the mode we are currently using
package payload

import "core:fmt"
import "core:strings"
import "core:time"

CARP_SKEVER :: "2492"
SIMMER_ITEM :: "2492"
STIRFRY_ITEM :: "2"

TOMATOES :: "2579"
LETTUCE :: "2578"


Chef_mode :: enum {
	ROAST,
	SIMMER,
	STIRFRY,
	CHOPPING,
}

handle_cooking_packet :: proc(words: []string) {
	switch words[0] {
	case EFF_S:
		cook_handle_eff_s(words)
	// case:
	// find the sent cooking packet ID and repeat that ID
	}
}

handle_sent_cooking_packet :: proc(words: []string) {
	switch words[0] {
	case U_S:
		cook_handle_eff_s(words)
	}
}
currently_cooking := ""
// u_s 2 1 355473 2486 1 0
// look for u_s x 1 botid ITEMID 1 0. then save to global variable and spam that one.
set_modes :: proc(words: []string) {
	log_info(fmt.tprintf("set_modes called with %s", words[0]))
	if bot.chef_mode == .CHOPPING do return
	if len(words) < 6 do return
	if words[2] != "1" do return
	if words[3] != bot.playerID do return
	currently_cooking = words[4]
	switch words[1] {
	case "2":
		bot.chef_mode = .ROAST
	case "4":
		bot.chef_mode = .SIMMER
	case "7":
		bot.chef_mode = .STIRFRY
	}
	log_info(
		fmt.aprintf(
			"set cooking item to %s and chef mode is %v",
			currently_cooking,
			bot.chef_mode,
		),
	)
}

// eff_s 1 355473 7790 0
cook_handle_eff_s :: proc(words: []string) {
	if bot.chef_mode == .CHOPPING do return
	if len(words) < 5 do return
	if words[1] != "1" do return
	if words[2] != bot.playerID do return
	if words[3] != "7790" do return
	if words[4] != "0" do return
	packet := ""
	switch bot.chef_mode {
	case .ROAST:
		packet = roasting_packet(currently_cooking)
	case .SIMMER:
		packet = simmer_packet(currently_cooking)
	case .STIRFRY:
		packet = stirfry_packet(currently_cooking)
	case .CHOPPING:
	}

	add_bot_skill_que(1000, "3")
	add_packet_skill_que(5000, packet, true)
	// delete(packet) //TODO where to delete this packet? or do I care about this leak?
}

// u_s 2 1 355473 2486 1 0
roasting_packet :: proc(food: string) -> string {
	return fmt.aprintf("u_s 2 1 %s %s 1 0", bot.playerID, food)
}

simmer_packet :: proc(food: string) -> string {
	return fmt.aprintf("u_s 4 1 %s %s 1 0", bot.playerID, food)
}

stirfry_packet :: proc(food: string) -> string {
	return fmt.aprintf("u_s 6 1 %s %s 1 0", bot.playerID, food)
}

start_chopping :: proc() {
	log_info("chopping started. qued 100x tomato chopping")
	packet := chop_packet(TOMATOES)
	// just spam the skill que full of chop packets and then reset at some point
	for i in 0 ..< 100 {
		add_packet_skill_que(5000, packet, true)
	}
	// delete(packet) //TODO where to delete this packet? or do I care about this leak?
}

chop_packet :: proc(item: string) -> string {
	//u_s 1 1 355473 2579 5 0
	return fmt.aprintf("u_s 1 1 %s %s 5 0", bot.playerID, item)
}
