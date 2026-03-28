#+build windows
package payload

import "core:fmt"
import "core:strings"
import "core:time"

BotState :: union {
	DPSCheckState,
	// MobGrindingState,
	// IceFlowerState,
}

Mode :: enum {
	PAUSED,
	FISHING,
	COOKING,
	DPSCheck,
	BUFFING,
	ICE_FLOWER,
	MOB_GRINDING,
}

que_type :: enum {
	skill,
	buff,
	send_packet,
	recv_packet,
}

Skill :: struct {
	ready:     bool,
	cd:        time.Duration,
	cdTimer:   time.Time,
	castLevel: u8,
	key:       string,
	target:    bool,
	last_cast: time.Time, // buff better use this to check cd
}

Skill_que :: struct {
	skill:       string,
	castTime:    time.Time,
	delay:       time.Duration,
	full_packet: string,
	type:        que_type,
	important:   bool,
	target:      bool,
}

Bot :: struct {
	playerID:      string,
	playerSP:      u8,
	level:         int,
	mode:          Mode,
	state:         BotState,
	buffing:       Buffers,
	last_activity: time.Time,
	currentDelay:  time.Duration,
	skill_que:     [dynamic]Skill_que,
	player_list:   map[i32]string, //id -> name. no clue about this anymore
}

bot: Bot

init_bot :: proc() {
	modinfo := getModuleInfo()
	id, ok := get_player_id_internal(cast(^u8)modinfo.lpBaseOfDll, u32(modinfo.SizeOfImage))
	if ok {
		log_info(fmt.tprintf("player id: %d", id^))
	} else {
		log_info("failed to get id")
	}
	sp, ok2 := get_player_sp_internal(cast(^u8)modinfo.lpBaseOfDll, u32(modinfo.SizeOfImage))
	if ok2 {
		log_info(fmt.tprintf("player sp level: %d", sp^))
	} else {
		log_info("failed to get sp level")
	}
	ok3 := get_packetlogger_addrs(cast(^u8)modinfo.lpBaseOfDll, u32(modinfo.SizeOfImage))
	if ok3 {
		init_packetlogger(&packet_queue, &send_queue)
		hook_recv()
		hook_send()
		log_info("packetlogger hooked")
	} else {
		log_warn("failed to get packetlogger addresses")
	}
	bot = Bot {
		playerID    = fmt.aprintf("%d", id^),
		playerSP    = sp^,
		level       = 93, // hardcoded until I find offsets for this
		mode        = .BUFFING,
		state       = DPSCheckState{},
		player_list = make(map[i32]string),
	}
	update_state()
	choose_buffer()
}


bot_tick :: proc() {
	if bot.mode == .PAUSED {
		if len(bot.skill_que) != 0 {
			//clean que. will this cause memory leaks?
			clear(&bot.skill_que)
		}
		return
	}
	if len(bot.skill_que) != 0 {
		next := bot.skill_que[0]
		if time.since(next.castTime) > 0 {
			switch next.type {
			case .skill:
				castSkill(next.skill)
			case .send_packet:
				send_packet(next.full_packet)
			case .recv_packet:
				recv_packet(next.full_packet)
			case .buff:
				castBuff(next.skill, next.target)
			}
			bot.last_activity = time.now()
			bot.currentDelay -= next.delay
			if next.important {
				log_this := fmt.aprintf("doing: %s type %s", next.full_packet, next.type)
				log_important(log_this)
				delete(log_this)
			}
			ordered_remove(&bot.skill_que, 0)
		}
	}
}

add_packet_skill_que :: proc(waitMS: int, packet: string, important := false) {
	delay := time.Duration(waitMS) * time.Millisecond + time.Duration(iteration)
	bot.currentDelay += delay
	// Schedule relative to now + total accumulated delay so skills fire sequentially
	skill_call_time := time.time_add(time.now(), bot.currentDelay)
	item := Skill_que {
		castTime    = skill_call_time,
		delay       = delay,
		type        = .send_packet,
		full_packet = packet,
		important   = important,
	}
	append(&bot.skill_que, item)
}

castSkill :: proc(skillID: string) {
	bot.last_activity = time.now()
	skill_packet := fmt.aprintf("u_s %s 1 %s", skillID, bot.playerID)
	// log_info(fmt.tprintf("casting skill %s", skill_packet))
	send_packet(skill_packet)
	delete(skill_packet)
}

bot_afk_check :: proc() {
	if bot.mode == .PAUSED do return
	since_last_action := time.since(bot.last_activity)
	if since_last_action < time.Minute * 5 do return
	#partial switch bot.mode {
	case .FISHING:
		fish_reset_skills()
		castSkill("1")
	}
}

add_bot_skill_que :: proc(waitMS: int, skill: string, important := false) {
	delay := time.Duration(waitMS) * time.Millisecond + time.Duration(iteration)
	bot.currentDelay += delay
	// Schedule relative to now + total accumulated delay so skills fire sequentially
	skill_call_time := time.time_add(time.now(), bot.currentDelay)
	item := Skill_que {
		castTime  = skill_call_time,
		skill     = skill,
		delay     = delay,
		type      = .skill,
		important = important,
	}
	append(&bot.skill_que, item)
}


recv_packet_skill_que :: proc(waitMS: int, packet: string, important := false) {
	delay := time.Duration(waitMS) * time.Millisecond + time.Duration(iteration)
	bot.currentDelay += delay
	// Schedule relative to now + total accumulated delay so skills fire sequentially
	skill_call_time := time.time_add(time.now(), bot.currentDelay)
	item := Skill_que {
		castTime    = skill_call_time,
		delay       = delay,
		type        = .recv_packet,
		full_packet = packet,
		important   = important,
	}
	append(&bot.skill_que, item)
}

update_state :: proc() {
	bot.last_activity = time.now()
	#partial switch bot.mode {
	case .FISHING:
		expBuff.ready = true
		maintainLineBuff.ready = true
		baitSkill.ready = true
		proCastLine.ready = true
	case .DPSCheck:
		mapper := make(map[string]raid_player) //mem leaks xddd
		DPS_state := DPSCheckState {
			mode      = .IC,
			raid_list = mapper,
		}
		bot.state = DPS_state
	case .PAUSED:
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
		handle_DPSCheck_packet(words)
	case .BUFFING:
		handle_buff_packet(words)
	case .COOKING:
	// broken. dont use
	// handle_cooking_packet(words)
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
	#partial switch bot.mode {
	case .PAUSED, .DPSCheck, .BUFFING:
		//to prevent double running this. 1 is new map, 0 is old map
		if len(words) >= 4 && words[3] == "1" {
			recv_packet_skill_que(1000, "tcrank 1")
			fmt.println("Map change!!!")
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
	bot.currentDelay = 0
	log_info("[F5] paused")
	reset_skill_que()
}

reset_skill_que :: proc() {
	bot.currentDelay = 0
	log_info(
		fmt.tprintf(
			"reset que, sk len: %d, packet_queue %d",
			len(bot.skill_que),
			len(packet_queue.queue),
		),
	)
	clear(&bot.skill_que)
	clear(&packet_queue.queue)
}


// should find admin entrance but not really. useless at the moment for this purpose.
// TODO: log all in entries to a file so we can analyze them?
handleIN :: proc(line: []string) {
	if len(line) < 9 do return
	if line[1] != "1" do return // actual player in
	// log_line := strings.join(line, " ")
	// log_important(log_line)
	// if line[8] != "2" { // most definitely not a admin alert
	// 	log_important("admin one???")
	// 	// bot_pause()
	// 	// delete(log_line)
	// 	// alert()
	// 	// play_alert_sound()
	// 	return
	// }
	name, id := line[1], line[3]
	intID := parse_str_int(id)
	if intID == 0 do return
	heapName := strings.clone(name) //mem leak if not deleted
	// player_list:   map[i32]string, //id -> name
	bot.player_list[intID] = heapName //takes about 36kb when up to 500 entries so w/e
}
