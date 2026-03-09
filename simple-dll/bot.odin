#+build windows
package payload

import "core:fmt"
import "core:math/rand"
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
Bot :: struct {
	playerID:      string,
	playerSP:      u8,
	stop:          bool,
	mode:          Mode,
	state:         BotState,
	last_activity: time.Time,
	next_action:   time.Time,
}

init_bot :: proc() -> Bot {
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
	bot := Bot {
		playerID    = fmt.aprintf("%d", id^),
		playerSP    = sp^,
		stop        = false,
		mode        = .FISHING,
		state       = FishingState{},
		next_action = time.now(),
	}
	update_state(&bot)
	return bot
}
bot_tick :: proc(bot: ^Bot) {
	if bot.mode == .PAUSED do return

	// If we are still waiting for next_action, do nothing
	if time.diff(time.now(), bot.next_action) < 0 {
		return
	}

	if bot.mode == .FISHING {
		fishing_state := &bot.state.(FishingState)
		if fishing_state.needs_cast {
			fish_checkBuffs(bot)
		}
	}
}
//delay with min value and extra random value
get_sleep_time :: proc(durationMS: int) -> time.Time {
	return time.time_add(time.now(), durationMS)
}

update_state :: proc(bot: ^Bot) {
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
			needs_cast  = true,
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
