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
			proCastLine = true,
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

// Generic packet handler that dispatches to mode-specific handlers
handle_packet :: proc(words: []string) {
	switch bot.mode {
	case .PAUSED:
		handleC_map(words)
	//do nothing
	case .FISHING:
		handle_fishing_packet(words)
	case .MOB_GRINDING:
		handle_mob_grinding_packet(words)
	case .ICE_FLOWER:
		handle_ice_flower_packet(words)
	case .DPSCheck:
	// handle_DPSCheck_packet(bot, words)
	}
}

// Mob grinding mode packet handler (placeholder)
handle_mob_grinding_packet :: proc(words: []string) {
	// Add mob grinding specific packet handlers here
	// Note: c_map and in packets are handled immediately in main thread
}

// Ice flower mode packet handler (placeholder)
handle_ice_flower_packet :: proc(words: []string) {
	// Add ice flower specific packet handlers here
	// Note: c_map and in packets are handled immediately in main thread
}
// map changed, if fishing is due to admin
handleC_map :: proc(words: []string) {
	switch bot.mode {
	case .PAUSED, .DPSCheck:
		//to prevent double running this. 1 is new map, 0 is old map
		if len(words) >= 4 && words[3] == "1" {
			fmt.println("Map change!!!")
			recv_packet("tcrank 1")
		}
	case .FISHING, .ICE_FLOWER, .MOB_GRINDING:
		log_info("admin alert")
		bot_pause()
		alert()
	}
}

bot_pause :: proc() {
	bot.mode = .PAUSED
	// flush any queued skills
	clear(&bot.skill_que)
	bot.currentDelay = 0
	log_info("[F5] paused")
}

// should find admin entrance but not really. useless at the moment for this purpose.
// TODO: log all in entries to a file so we can analyze them?
handleIN :: proc(line: []string) {
	if len(line) < 9 do return
	if line[1] != "1" do return
	if line[8] != "2" && bot.mode == .FISHING {
		log_info("admin alert")
		bot_pause()
		alert()
		return
	}
	// dps tracker stuff. save for later
	// name, id := line[2], line[4]
	// intID := parse_str_int(id)
	// if intID == 0 do return
	// heapName := strings.clone(name) //mem leak if not deleted
	// // player_list:   map[i32]string, //id -> name
	// bot.player_list[intID] = heapName //takes about 36kb when up to 500 entries so w/e
}
