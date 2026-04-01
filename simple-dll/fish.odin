#+build windows
package payload

import "core:fmt"
import "core:strings"
import "core:time"

expBuff := Skill {
	ready     = true,
	cd        = time.Second * 205,
	castLevel = 25,
	key       = "8",
}

maintainLineBuff := Skill {
	ready     = true,
	cd        = time.Second * 125,
	castLevel = 25,
	key       = "9",
}

baitSkill := Skill {
	ready     = true,
	cd        = time.Second * 125,
	castLevel = 3,
	key       = "3",
}

proCastLine := Skill {
	ready     = true,
	cd        = time.Second * 65,
	castLevel = 45,
	key       = "10",
}

outOfBaits := false
fish_caught := 0


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
	case IN:
		handleIN(words)
	case C_MAP:
		handleC_map(words)
	case SAY:
		handle_say(words)
	}
}

// GURI 6 1 <playerID> 30/31 → fish detected, pick it up then start fishing again
fish_handleGURI :: proc(line: []string) {
	if len(line) < 6 {return}
	if line[3] != bot.playerID {return}
	if len(bot.skill_que) > 0 { 	// good to have as we get this guri multiple times
		// log_warn("early return in guri: queue not empty")
		return
	}
	switch line[4] {
	case "30":
		fish_caught += 1
		// Queue: pick up fish, then run the full buff+cast chain
		add_bot_skill_que(200, "2")
		fish_startFishing()
	case "31":
		fish_caught += 1
		log_info(fmt.tprintf("fish: %d legendary fish!!", fish_caught))
		add_bot_skill_que(200, "2")
		fish_startFishing()
	}
}

// Queue all ready buffs then cast the line — mirrors BotManager::startFishing
fish_startFishing :: proc() {
	if bot.mode != .FISHING {return}

	if outOfBaits && bot.playerSP >= baitSkill.castLevel {
		// No bait: only cast line if bait skill is ready (will re-bait)
		if baitSkill.ready {
			add_bot_skill_que(5000, baitSkill.key)
			baitSkill.ready = false
			baitSkill.cdTimer = time.now()
		}
	}

	if expBuff.ready && bot.playerSP < 45 && bot.playerSP >= expBuff.castLevel {
		add_bot_skill_que(5000, expBuff.key)
		expBuff.ready = false
		expBuff.cdTimer = time.now()
	}

	if maintainLineBuff.ready && bot.playerSP >= maintainLineBuff.castLevel {
		add_bot_skill_que(5000, maintainLineBuff.key)
		maintainLineBuff.ready = false
		maintainLineBuff.cdTimer = time.now()
	}

	if baitSkill.ready && bot.playerSP >= baitSkill.castLevel {
		add_bot_skill_que(5000, baitSkill.key)
		baitSkill.ready = false
		baitSkill.cdTimer = time.now()
	}

	if proCastLine.ready && bot.playerSP >= proCastLine.castLevel {
		add_bot_skill_que(5000, proCastLine.key)
		proCastLine.ready = false
		proCastLine.cdTimer = time.now()
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
	alert("damage to bot")
}

handle_say :: proc(lines: []string) {
	if len(lines) < 6 do return
	if lines[1] != "1" do return
	if lines[2] != bot.playerID do return
	if lines[3] != "10" do return
	log_important(fmt.tprintf("say check: %s", strings.join(lines, " ", context.temp_allocator)))
}


// SAYI 1 <playerID> ... 2497 → out of baits
fish_handleSayi :: proc(line: []string) {
	if len(line) < 5 {return}
	if line[1] != "1" {return}
	if line[2] != bot.playerID {return}
	if line[4] == "2497" {
		outOfBaits = true
		log_info("out of baits")
	}
}

// SR <skillID> → skill cooldown expired, mark ready; bait SR restarts fishing if needed
fish_handleSR :: proc(words: []string) {
	if bot.mode != .FISHING || len(words) < 2 do return
	skillID := words[1]

	switch skillID {
	case baitSkill.key:
		baitSkill.ready = true
		// Mirror reference: if we ran out of baits and bait skill is now ready, restart
		if outOfBaits {
			fish_startFishing()
		}
	case expBuff.key:
		expBuff.ready = true
	case maintainLineBuff.key:
		maintainLineBuff.ready = true
	case proCastLine.key:
		proCastLine.ready = true
	}
}

fish_reset_skills :: proc() {
	if bot.mode != .FISHING {return}
	maintainLineBuff.ready = true
	baitSkill.ready = true
	proCastLine.ready = true
	log_info("bot skills are reset")
}
