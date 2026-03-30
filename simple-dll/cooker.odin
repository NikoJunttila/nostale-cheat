//TODO way to make this better would to make the cooked item ID more dynamic so we start manually cooking and then start the loop with item id after getting first eff_s
// eff_s does not have item ID so we need to check for sent packets when we start cooking item
// while doing this we could also figure out the mode we are currently using
package payload

import "core:fmt"
import "core:strings"
import "core:time"

handle_cooking_packet :: proc(words: []string) {
	switch words[0] {
	case EFF_S:
		cook_handle_eff_s(words)
	}
}
handle_sent_cooking_packet :: proc(words: []string) {
	switch words[0] {
	case U_S:
		set_modes(words)
	}
}
currently_cooking := ""
bot_cooking_skill := ""
// u_s 2 1 355473 2486 1 0
// look for u_s x 1 botid ITEMID 1 0. then save to global variable and spam that one.

// [4368] [12:08:05] [v1.0.172] [PAYLOAD] INFO: set modes called: u_s 2 1 355473
set_modes :: proc(words: []string) {
	log_info(fmt.tprintf("set modes called: %s", strings.join(words, " ", context.temp_allocator)))
	if len(words) < 5 do return
	if words[2] != "1" do return
	if words[3] != bot.playerID do return
	if words[1] == "1" do chopping(words)
	else do cooking(words)
}

cooking :: proc(words: []string) {
	// Must clone — words[] points into queue memory that gets freed after this returns
	if currently_cooking != "" do delete(currently_cooking)
	currently_cooking = strings.clone(words[4])
	if bot_cooking_skill != "" do delete(bot_cooking_skill)
	bot_cooking_skill = strings.clone(words[1])
	log_info(
		fmt.aprintf(
			"set cooking item to %s and skill is %s",
			currently_cooking,
			bot_cooking_skill,
		),
	)
}
currently_chopping := ""
chopping :: proc(words: []string) {
	if currently_chopping != "" do delete(currently_cooking)
	currently_chopping = words[4]
	packet := chop_packet()
	log_info(fmt.tprintf("sending: %s", packet))
	add_packet_skill_que(6000, packet, true)
}

// eff_s 1 355473 7790 0
cook_handle_eff_s :: proc(words: []string) {
	if len(words) < 5 do return
	if words[1] != "1" do return
	if words[2] != bot.playerID do return
	if words[3] != "7790" do return
	if words[4] != "0" do return
	log_info("finished cooking")
	add_bot_skill_que(1000, "3")
	packet := cooking_packet()
	// this gets logged
	// [4368] [12:09:01] [v1.0.172] [PAYLOAD] INFO: sending: u_s 2 1 355473 $]
	log_info(fmt.tprintf("sending: %s", packet))
	add_packet_skill_que(6000, packet, true)
	// delete(packet) //I do not care about this leak
}

// u_s 2 1 355473 2486 1 0
cooking_packet :: proc() -> string {
	return fmt.aprintf("u_s %s 1 %s %s 1 0", bot_cooking_skill, bot.playerID, currently_cooking)
}

chop_packet :: proc() -> string {
	//u_s 1 1 355473 2579 5 0
	return fmt.aprintf("u_s 1 1 %s %s 5 0", bot.playerID, currently_chopping)
}
