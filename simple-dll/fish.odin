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
	outOfBaits:    bool,
	proCastLine:   bool,
	proCastLineCD: time.Time,
}

// Fishing mode packet handler
handle_fishing_packet :: proc(words: []string) {
	switch words[0] {
	case GURI:
		fish_handleGURI(words)
	case SAYI:
		fish_handleSayi(words)
	case SU:
		fish_handleSU3(words)
	case SR:
		fish_handleSR(words)
	}
}

// GURI 6 1 <playerID> 30/31 → fish detected, pick it up then start fishing again
fish_handleGURI :: proc(line: []string) {
	if len(line) < 6 {return}
	if line[3] != bot.playerID {return}
	fishing_state := &bot.state.(FishingState)
	log_info(fmt.tprintf("guri line spotted %s", line[4]))
	if len(bot.skill_que) > 0 {
		log_info("early return in guri: queue not empty")
		return
	}
	switch line[4] {
	case "30":
		fishing_state.fish_caught += 1
		log_info(fmt.tprintf("fish: %d", fishing_state.fish_caught))
		// Queue: pick up fish, then run the full buff+cast chain
		add_bot_skill_que(200, "2")
		fish_startFishing()
	case "31":
		log_info("legendary fish!!")
		fishing_state.fish_caught += 1
		fishing_state.leg_fish += 1
		log_info(
			fmt.tprintf("fish: %d leg: %d", fishing_state.fish_caught, fishing_state.leg_fish),
		)
		// Queue: pick up fish, then run the full buff+cast chain
		add_bot_skill_que(200, "2")
		fish_startFishing()
	}
}

// Queue all ready buffs then cast the line — mirrors BotManager::startFishing
fish_startFishing :: proc() {
	if bot.mode != .FISHING {return}
	fishing_state := &bot.state.(FishingState)

	if fishing_state.outOfBaits {
		// No bait: only cast line if bait skill is ready (will re-bait)
		if fishing_state.baitSkill {
			add_bot_skill_que(5000, "3")
			fishing_state.baitSkill = false
			fishing_state.baitCast = time.now()
		}
		// Don't cast the line; wait for SR on bait skill to restart
		return
	}

	// expBuff — skip at max SP level 45
	if fishing_state.expBuff && bot.playerSP < 45 {
		add_bot_skill_que(5000, "8")
		fishing_state.expBuff = false
	}

	// lineBuff
	if fishing_state.lineBuff {
		add_bot_skill_que(5000, "9")
		fishing_state.lineBuff = false
		fishing_state.lineCast = time.now()
	}

	// baitSkill
	if fishing_state.baitSkill {
		add_bot_skill_que(5000, "3")
		fishing_state.baitSkill = false
		fishing_state.baitCast = time.now()
	}

	// proCastLine — if ready, cast it and return (it auto-casts the line)
	if fishing_state.proCastLine {
		add_bot_skill_que(5000, "10")
		fishing_state.proCastLine = false
		fishing_state.proCastLineCD = time.now()
		return
	}

	// Plain cast line
	add_bot_skill_que(5500, "1")
}

// SU 3 <casterID> ... <skillID> → skill went on cooldown
fish_handleSU3 :: proc(line: []string) {
	if len(line) < 18 do return
	if line[1] != "3" {return}
	if line[4] != bot.playerID {return}
	bot.mode = .PAUSED
	log_info("bot paused due to damage")
}

// SAYI 1 <playerID> ... 2497 → out of baits
fish_handleSayi :: proc(line: []string) {
	if len(line) < 5 {return}
	if line[1] != "1" {return}
	if line[2] != bot.playerID {return}
	if line[4] == "2497" {
		fishing_state := &bot.state.(FishingState)
		fishing_state.outOfBaits = true
		log_info("out of baits")
		// If bait skill is already ready, restart right away
		if fishing_state.baitSkill && len(bot.skill_que) == 0 {
			fish_startFishing()
		}
	}
}

// SR <skillID> → skill cooldown expired, mark ready; bait SR restarts fishing if needed
fish_handleSR :: proc(words: []string) {
	if bot.mode != .FISHING || len(words) < 2 do return
	fishing_state := &bot.state.(FishingState)
	skillID := words[1]

	switch skillID {
	case "3":
		log_info(fmt.tprintf("reset skill %s", skillID))
		fishing_state.baitSkill = true
		// Mirror reference: if we ran out of baits and bait skill is now ready, restart
		if fishing_state.outOfBaits && len(bot.skill_que) == 0 {
			fishing_state.outOfBaits = false
			fish_startFishing()
		}
	case "8":
		fishing_state.expBuff = true
	case "9":
		log_info(fmt.tprintf("reset skill %s", skillID))
		fishing_state.lineBuff = true
	case "10":
		log_info(fmt.tprintf("reset skill %s", skillID))
		fishing_state.proCastLine = true
	}
}

fish_reset_skills :: proc() {
	if bot.mode != .FISHING {return}
	fishing_state := &bot.state.(FishingState)
	fishing_state.lineBuff = true
	fishing_state.baitSkill = true
	fishing_state.proCastLine = true
	log_info("bot skills are reset")
}
