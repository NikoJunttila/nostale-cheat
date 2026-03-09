#+build windows
package payload

import "core:fmt"
import "core:time"


// Mode-specific state
FishingState :: struct {
	fish_caught:   i32,
	leg_fish:      i32,
	expBuff:       bool,
	lineBuff:      bool,
	lineCast:      time.Time,
	baitSkill:     bool,
	baitCast:      time.Time,
	castLine:      bool,
	outOfBaits:    bool,
	proCastLine:   bool,
	proCastLineCD: time.Time,
	covert:        bool,
	needs_cast:    bool,
}

// Fishing mode packet handler
handle_fishing_packet :: proc(bot: ^Bot, words: []string) {
	switch words[0] {
	case GURI:
		log_info("handling guri")
		fish_handleGURI(words, bot)
	case SAYI:
		fish_handleSayi(bot, words)
	case SU:
		fish_handleSU3(bot, words)
	}
}

fish_handleGURI :: proc(line: []string, bot: ^Bot) {
	//fmt.println("handling guri:", line)
	if len(line) < 6 {return}
	if line[3] != bot.playerID {return}
	fishing_state := &bot.state.(FishingState)
	switch line[4] {
	case "30":
		fish_castSkill("2", bot)
		fishing_state.fish_caught += 1
		fish_str := fmt.aprintf("fish: %d", fishing_state.fish_caught)
		log_info(fish_str)
		delete(fish_str)
		log_info("waiting after fish caught")
		bot.next_action = get_sleep_time(1000)
		fishing_state.needs_cast = true
	case "31":
		log_info("legendary fish!!")
		fish_castSkill("2", bot)
		fishing_state.fish_caught += 1
		fishing_state.leg_fish += 1
		fish_str := fmt.aprintf("fish: %d", fishing_state.fish_caught)
		log_info(fish_str)
		delete(fish_str)
		bot.next_action = get_sleep_time(1000)
		fishing_state.needs_cast = true
	}
}

fish_handleSU3 :: proc(bot: ^Bot, line: []string) {
	if len(line) < 18 do return
	if line[1] != "3" {return}
	if line[4] != bot.playerID {return}
	bot.mode = .PAUSED
	// playAlert()
	log_info("bot paused due to damage")
}

fish_handleSayi :: proc(bot: ^Bot, line: []string) {
	if len(line) < 5 {return}
	if line[1] != "1" {return}
	if line[2] != bot.playerID {return}
	if line[4] == "2497" {
		fishing_state := &bot.state.(FishingState)
		fishing_state.outOfBaits = true
		log_info("out of baits")
	}
}
fish_handleSR :: proc(bot: ^Bot, skillID: string) {
	if bot.mode != .FISHING {return}
	fishing_state := &bot.state.(FishingState)

	switch skillID {
	case "1":
		fishing_state.castLine = true
	//fmt.println("skill 1 reset")
	case "3":
		fishing_state.baitSkill = true
		if fishing_state.outOfBaits {
			fish_checkBuffs(bot)
		}
	// fmt.println("\n\nskill 3 reset \n\n")
	case "8":
		fishing_state.expBuff = true
	// fmt.println("skill 8 reset")
	case "5":
		fishing_state.covert = true
	// fmt.println("skill 5 reset")
	case "9":
		fishing_state.lineBuff = true
	// fmt.println("\n\nskill 9 reset\n\n")
	case "10":
		fishing_state.proCastLine = true
	// fmt.println("skill 10 reset")
	}
}
fish_checkBuffs :: proc(bot: ^Bot) {
	if bot.mode != .FISHING {return}
	fishing_state := &bot.state.(FishingState)

	//lvl50 no need for exp
	// if fishing_state.expBuff {
	// 	castSkill("8", &bot.socket)
	// 	fishing_state.expBuff = false
	// 	fmt.println("bot exp buff = ", fishing_state.expBuff)
	// 	rs(2000, 1000)
	// }
	if fishing_state.lineBuff {
		fish_castSkill("9", bot)
		fishing_state.lineBuff = false
		fishing_state.lineCast = time.now()
		bot.next_action = get_sleep_time(1000)
		return
	}
	if fishing_state.baitSkill {
		fish_castSkill("3", bot)
		fishing_state.baitSkill = false
		fishing_state.baitCast = time.now()
		bot.next_action = get_sleep_time(1000)
		return
	}
	if fishing_state.outOfBaits {return}
	if fishing_state.proCastLine {
		fish_castSkill("10", bot)
		fishing_state.proCastLine = false
		fishing_state.proCastLineCD = time.now()
		bot.next_action = get_sleep_time(1000)
		fishing_state.needs_cast = false
		return
	}
	fish_castSkill("1", bot)
	bot.next_action = get_sleep_time(1000)
	fishing_state.needs_cast = false
}

fish_castSkill :: proc(skillID: string, bot: ^Bot) {
	bot.last_activity = time.now()
	skill_packet := fmt.aprintf("u_s %s 1 %s", skillID, bot.playerID)
	log_info(fmt.tprintf("casting skill %s", skill_packet))
	send_packet(skill_packet)
	delete(skill_packet)
}

fish_reset_skills :: proc(bot: ^Bot) {
	if bot.mode != .FISHING {return}
	fishing_state := &bot.state.(FishingState)
	fishing_state.lineBuff = true
	fishing_state.baitSkill = true
	fishing_state.proCastLine = true
	log_info("bot skills are reset")
}
