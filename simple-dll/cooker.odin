package payload

import "core:fmt"
import "core:strings"
import "core:time"

cooker_buffs := []Skill {
	{key = "6", cd = cd(185), castLevel = 15}, // cooking prep
	{key = "8", cd = cd(195), castLevel = 25}, // secret spice
	{key = "9", cd = cd(205), castLevel = 30}, // healthy eating
	{key = "10", cd = cd(205), castLevel = 40}, // sharpen knife
}


handle_cooking_packet :: proc(words: []string) {
	switch words[0] {
	case EFF_S:
		cook_handle_eff_s(words)
	case SAYI:
		cooking_sayi(words)
	}
}
handle_sent_cooking_packet :: proc(words: []string) {
	switch words[0] {
	case U_S:
		set_modes(words)
	}
}

cooking_sayi :: proc(words: []string) {
	if len(words) < 6 do return
	if words[1] != "1" do return
	if words[2] != bot.playerID do return
	if words[3] != "10" do return
	if words[4] != "158" do return
	log_info(fmt.tprintf("alert: %s", strings.join(words, " ", context.temp_allocator)))
	bot_pause()
	alert("out of incredients")
}

currently_cooking := ""
bot_cooking_skill := ""

set_modes :: proc(words: []string) {
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
	cast_cooking_buffs()
	packet := cooking_packet()
	add_packet_skill_que(6000, packet, true)
	// delete(packet) //I do not care about this leak
}

cast_cooking_buffs :: proc() {
	for &s in cooker_buffs {
		if check_time(s.last_cast, s.cd) {
			if bot.playerSP < s.castLevel do continue
			buf_skill_que(3200, s.key, s.target)
			s.last_cast = time.now()
		}
	}
}

// u_s 2 1 355473 2486 1 0
cooking_packet :: proc() -> string {
	if bot_cooking_skill == "" || currently_cooking == "" {
		bot_pause()
		alert("failed to get items")
	}
	return fmt.aprintf("u_s %s 1 %s %s 1 0", bot_cooking_skill, bot.playerID, currently_cooking)
}

chop_packet :: proc() -> string {
	return fmt.aprintf("u_s 1 1 %s %s 5 0", bot.playerID, currently_chopping)
}
