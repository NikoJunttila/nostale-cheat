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

fish_handleGURI :: proc(line: []string) {
	if len(line) < 6 {return}
	if line[3] != bot.playerID {return}
	fishing_state := &bot.state.(FishingState)
	log_info(fmt.tprintf("guri line spotted %s", line[4]))
	if len(bot.skill_que) > 0 {
		log_info("early return in guri")
		return
	}
	switch line[4] {
	case "30":
		castSkill("2")
		fishing_state.fish_caught += 1
		fish_str := fmt.aprintf("fish: %d", fishing_state.fish_caught)
		log_info(fish_str)
		delete(fish_str)
		fish_checkBuffs()
	case "31":
		log_info("legendary fish!!")
		castSkill("2")
		fishing_state.fish_caught += 1
		fishing_state.leg_fish += 1
		fish_str := fmt.aprintf("fish: %d", fishing_state.fish_caught)
		log_info(fish_str)
		delete(fish_str)
		fish_checkBuffs()
	}
}

fish_handleSU3 :: proc(line: []string) {
	if len(line) < 18 do return
	if line[1] != "3" {return}
	if line[4] != bot.playerID {return}
	bot.mode = .PAUSED
	// playAlert()
	log_info("bot paused due to damage")
}

fish_handleSayi :: proc(line: []string) {
	if len(line) < 5 {return}
	if line[1] != "1" {return}
	if line[2] != bot.playerID {return}
	if line[4] == "2497" {
		fishing_state := &bot.state.(FishingState)
		fishing_state.outOfBaits = true
		log_info("out of baits")
	}
}
fish_handleSR :: proc(words: []string) {
	if bot.mode != .FISHING || len(words) < 2 do return
	fishing_state := &bot.state.(FishingState)
	skillID := words[1]
	log_info(fmt.tprintf("reset skill %s", skillID))

	switch skillID {
	case "1":
		fishing_state.castLine = true
	case "3":
		fishing_state.baitSkill = true
	case "8":
		fishing_state.expBuff = true
	case "5":
		fishing_state.covert = true
	case "9":
		fishing_state.lineBuff = true
	case "10":
		fishing_state.proCastLine = true
	}
}
fish_checkBuffs :: proc() {
	if bot.mode != .FISHING {return}
	fishing_state := &bot.state.(FishingState)
	if fishing_state.outOfBaits {return}
	//lvl45 no need for exp
	if fishing_state.expBuff && bot.playerSP < 45 {
		add_bot_skill_que(5000, "8")
		fishing_state.expBuff = false
	}
	if fishing_state.lineBuff {
		add_bot_skill_que(5000, "9")
		fishing_state.lineBuff = false
		fishing_state.lineCast = time.now()
	}
	if fishing_state.baitSkill {
		add_bot_skill_que(5000, "3")
		fishing_state.baitSkill = false
		fishing_state.baitCast = time.now()
	}
	if fishing_state.proCastLine {
		add_bot_skill_que(5000, "10")
		fishing_state.proCastLine = false
		fishing_state.proCastLineCD = time.now()
	}
	add_bot_skill_que(4000, "1")
}


fish_reset_skills :: proc() {
	if bot.mode != .FISHING {return}
	fishing_state := &bot.state.(FishingState)
	fishing_state.lineBuff = true
	fishing_state.baitSkill = true
	fishing_state.proCastLine = true
	log_info("bot skills are reset")
}
