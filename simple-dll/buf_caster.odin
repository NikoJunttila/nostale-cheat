package payload

import "core:fmt"
import "core:time"

// player id. hardcoded to be my main
TARGET_ID :: "355473"
THUMPS_UP_ID :: "5084"


WK_BUFFER_ID :: "8109126"
HOLY_BUFFER_ID :: "8141324"

Buffers :: enum {
	HOLY,
	WK,
}

cd :: proc "contextless" (seconds: int) -> time.Duration {
	return time.Second * time.Duration(seconds)
}

// u_s 1 2 4592787 // target spell
holy_buffs := []Skill {
	{key = "1", target = true, cd = cd(3)},
	{key = "5", cd = cd(35)},
	{key = "7", cd = cd(20)},
	{key = "8", cd = cd(120)},
	{key = "9", cd = cd(120)},
}
wk_buffs := []Skill {
	{key = "3", cd = cd(60)},
	{key = "4", cd = cd(120)},
	{key = "6", cd = cd(120)},
	{key = "9", cd = cd(120)},
}


handle_buff_packet :: proc(words: []string) {
	if TARGET_ID == bot.playerID do return // hotkeys effect all injected programs so we just return from main as that is not buffer alt
	switch words[0] {
	case EFF:
		handle_eff_buff(words)
	}
}

// eff 1 355473 5084
handle_eff_buff :: proc(words: []string) {
	if len(words) < 4 do return
	if words[1] != "1" do return
	if words[2] != TARGET_ID do return
	if words[3] != THUMPS_UP_ID do return
	log_info("casting buffs")
	switch bot.buffing {
	case .HOLY:
		cast_buff_skills(&holy_buffs)
	case .WK:
		cast_buff_skills(&wk_buffs)
	}
}

cast_buff_skills :: proc(skills: ^[]Skill) {
	for &s in skills {
		if check_time(s.last_cast, s.cd) {
			buf_skill_que(2200, s.key, s.target)
			s.last_cast = time.now()
		}
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
	switch bot.playerID {
	case WK_BUFFER_ID:
		bot.buffing = .WK
	case HOLY_BUFFER_ID:
		bot.buffing = .HOLY
	}

	log_info(fmt.tprintf("bot is buffing. buffs from %v", bot.buffing))
}
