package payload

import "core:fmt"
import "core:strings"
import "core:time"

// player id. hardcoded to be my main
TARGET_ID :: "355473"
THUMPS_UP_ID :: "5084"

Buffers :: enum {
	HOLY,
	WK,
}

// holy
// u_s 1 2 4592787 // target spell
// u_s 9 1 8141324
// u_s 8 1 8141324
// u_s 7 1 8141324
// u_s 5 1 8141324
// wk, 3,4,6,9
holy_buffs := []Skill {
	{key = "1", target = true},
	{key = "5"},
	{key = "7"},
	{key = "8"},
	{key = "9"},
}
wk_buffs := []Skill{{key = "3"}, {key = "4"}, {key = "6"}, {key = "9"}}


handle_buff_packet :: proc(words: []string) {
	switch words[0] {
	case EFF:
		handle_eff_buff(words)
	}
}

// eff 1 355473 5084
// [09:46:20] [v1.0.134] [PAYLOAD] INFO: eff spotted eff 1 355473 5084
handle_eff_buff :: proc(words: []string) {
	log_info(fmt.tprintf("eff spotted %s len(%d)", strings.join(words, " "), len(words)))
	if len(words) < 4 do return
	if words[1] != "1" do return
	if words[2] != TARGET_ID do return
	eff_id := words[3]
	if eff_id != THUMPS_UP_ID {
		log_info(fmt.tprintf("no match: eff id %q wanted id %q", eff_id, THUMPS_UP_ID))
		return
	}
	log_info("casting buffs")
	switch bot.buffing {
	case .HOLY:
		cast_buff_skills(holy_buffs)
	case .WK:
		cast_buff_skills(wk_buffs)
	}
}

cast_buff_skills :: proc(skills: []Skill) {
	for s in skills {
		buf_skill_que(2500, s.key, s.target)
	}
}

buf_skill_que :: proc(waitMS: int, skill: string, target := false) {
	delay := time.Duration(waitMS) * time.Millisecond + time.Duration(iteration)
	bot.currentDelay += delay
	skill_call_time := time.time_add(time.now(), bot.currentDelay)
	item := Skill_que {
		castTime = skill_call_time,
		skill    = skill,
		delay    = delay,
		type     = .buff,
		target   = target,
	}
	append(&bot.skill_que, item)
}

castBuff :: proc(skillID: string, target: bool) {
	bot.last_activity = time.now()
	target_id := target ? TARGET_ID : bot.playerID
	skill_packet := fmt.aprintf("u_s %s 1 %s", skillID, target_id)
	send_packet(skill_packet)
	delete(skill_packet)
}

choose_buffer :: proc() {
	if bot.playerSP > 80 {
		bot.buffing = .WK
	} else {
		bot.buffing = .HOLY
	}
}
