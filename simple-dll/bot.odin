#+build windows
package payload

import "core:fmt"
import "core:time"

BotState :: union {
	FishingState,
	// MobGrindingState,
	// IceFlowerState,
	// DPSCheckState,
}

Mode :: enum {
	PAUSED,
	FISHING,
	DPSCheck,
	ICE_FLOWER,
	MOB_GRINDING,
}

Skill_que :: struct {
	skill:    string,
	castTime: time.Time,
	delay:    time.Duration,
}

Bot :: struct {
	playerID:      string,
	playerSP:      u8,
	mode:          Mode,
	state:         BotState,
	last_activity: time.Time,
	currentDelay:  time.Duration,
	skill_que:     [dynamic]Skill_que,
}

bot: Bot

init_bot :: proc() {
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
	ok3 := get_packetlogger_addrs(cast(^u8)modinfo.lpBaseOfDll, u32(modinfo.SizeOfImage))
	if ok3 {
		init_packetlogger(&packet_queue)
		hook_recv()
		log_info("packetlogger hooked")
	} else {
		log_warn("failed to get packetlogger addresses")
	}
	bot = Bot {
		playerID = fmt.aprintf("%d", id^),
		playerSP = sp^,
		mode     = .FISHING,
		state    = FishingState{},
	}
	update_state()
}


bot_tick :: proc() {
	if bot.mode == .PAUSED do return
	if len(bot.skill_que) != 0 {
		next := bot.skill_que[0]
		if time.since(next.castTime) > 0 {
			log_info("casting a skill from que")
			castSkill(next.skill)
			bot.last_activity = time.now()
			bot.currentDelay -= next.delay
			ordered_remove(&bot.skill_que, 0)
		}
	}
}

castSkill :: proc(skillID: string) {
	bot.last_activity = time.now()
	skill_packet := fmt.aprintf("u_s %s 1 %s", skillID, bot.playerID)
	log_info(fmt.tprintf("casting skill %s", skill_packet))
	send_packet(skill_packet)
	delete(skill_packet)
}

bot_afk_check :: proc() {
	if bot.mode == .PAUSED do return
	since_last_action := time.since(bot.last_activity)
	if since_last_action < time.Minute * 5 do return
	// reset skills and start again.
	#partial switch bot.mode {
	case .FISHING:
		fish_reset_skills()
		castSkill("2")
	}
}

add_bot_skill_que :: proc(waitMS: int, skill: string) {
	delay := time.Duration(waitMS) * time.Millisecond + time.Duration(iteration)
	bot.currentDelay += delay
	// Schedule relative to now + total accumulated delay so skills fire sequentially
	skill_call_time := time.time_add(time.now(), bot.currentDelay)
	item := Skill_que {
		castTime = skill_call_time,
		skill    = skill,
		delay    = delay,
	}
	append(&bot.skill_que, item)
}

update_state :: proc() {
	bot.last_activity = time.now()
	#partial switch bot.mode {
	case .FISHING:
		fishing_state := FishingState {
			expBuff     = true,
			lineBuff    = true,
			baitSkill   = true,
			castLine    = true,
			proCastLine = true,
			covert      = true,
		}
		bot.state = fishing_state
		fmt.println("fishing_state")
	case .PAUSED:
		fmt.println("bot is paused")
	// case .MOB_GRINDING:
	// 	mob_state := MobGrindingState {
	// 		health_potion_cd = true,
	// 		//rest
	// 	}
	// 	bot.state = mob_state
	// 	fmt.println("mob grind state")
	// case .DPSCheck:
	// 	mapper := make(map[string]raid_player) //mem leaks xddd
	// 	DPS_state := DPSCheckState {
	// 		mode      = .IC,
	// 		raid_list = mapper,
	// 	}
	// 	fmt.println("auto joining IC")
	// 	bot.state = DPS_state
	// case .ICE_FLOWER:
	}
}
