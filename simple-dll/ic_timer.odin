#+build windows
package payload

import "core:fmt"
import "core:time"

/*
Threshold (in action points) go as follows: x, 3*x, 6*x, 10*x

IC 1-39: its 37.5, so 37.5, 37.5*3, 37.5*6, 37.5*10
IC 40-49 and 50-59: its 75, so 75, 225, 450, 750
IC 60-69 and 70-79: its 112.5. so [...]
IC 80-99: its 150, so 150, 450, 900, 1500
*/
IC_80_99 :: 150

ICTimerState :: struct {
	total_dmg:         i32,
	current_round:     i32, //damage
	round_number:      int,
	activation_points: int,
	rewards_achieved:  bool,
	asgobas_event:     bool,
}

sit_down_kid :: proc() {
	sit_packet := fmt.tprintf("rest 3 1 %d", bot.playerID)
	log_info("sit down kid")
	send_packet(sit_packet)
}

reset_ic :: proc() {
	state := &bot.state.(ICTimerState)
	state = ICTimerState{}
}

walk_safe_spot :: proc() {
	walk_packet := "walk 35 68 1 16"
	log_info("walking to safe spot")
	send_packet(walk_packet)
}

// IC holy-buffer skill lists. cast_buff_skills only fires entries whose CD is up,
// so both lists are safe to call repeatedly.
//
// Off-cd rotation: cast periodically by IC_tick — no packet trigger, just whatever's ready.
ic_holy_offcd_buffs := []Skill {
	{key = "3", cd = cd(65)},
	{key = "5", cd = cd(40)},
	{key = "5", cd = cd(40)},
	{key = "9", cd = cd(120)},
}

// Reactive rotation: cast every time the buff target receives damage during IC.
ic_holy_damage_buffs := []Skill{{key = "1", cd = cd(3)}, {key = "7", cd = cd(20)}}

handle_ic_timer_packet :: proc(words: []string) {
	switch words[0] {
	case "qnamli":
		IC_handle_join(words)
	case "msgi":
		IC_handle_msgi(words)
	case "su":
		IC_handle_su(words)
		IC_handle_damage_received(words)
	case "c_map":
		handleC_map(words)
	case "in":
		handleIN(words)
	}
}

// Logged variant of cast_buff_skills — emits one line per buff actually queued so the IC
// rotations are visible without spamming when nothing fires.
IC_cast_buffs :: proc(skills: ^[]Skill, label: string) {
	for &s in skills {
		if check_time(s.last_cast, s.cd) {
			buf_skill_que(2200, s.key, s.target)
			s.last_cast = time.now()
			log_info(fmt.tprintf("[IC HOLY] %s buff key=%s queued", label, s.key))
		}
	}
}

// Periodic poll for the off-cd holy rotation. Called from bot_tick while bot.mode == .IC_TIMER.
// cast_buff_skills already gates each skill on its own CD, so calling this every tick is safe.
IC_tick :: proc() {
	if bot.playerID != HOLY_BUFFER_ID do return
	state := &bot.state.(ICTimerState)
	if state.round_number == 0 do return
	IC_cast_buffs(&ic_holy_offcd_buffs, "off-cd")
}

// HP potion bound to inventory slot 41 (hotkey 5). 500ms local cooldown to avoid spamming on continuous damage ticks.
hp_potion_last_use: time.Time
HP_POTION_CD :: 500 * time.Millisecond

// uses first item in potion inventory
use_hp_potion :: proc() {
	if !check_time(hp_potion_last_use, HP_POTION_CD) do return
	packet := fmt.aprintf("u_i 1 %s 1 0 0 0", bot.playerID)
	send_packet(packet)
	delete(packet)
	hp_potion_last_use = time.now()
}

// su <caster_type> <caster_id> <target_type> <target_id> ... <dmg> ... <current_hp> <max_hp>
// su 3 41003 1 355473 0 9 11 0 0 0 1 41 1046 0 0 13380 32292
// Fire reactive buffs when bot is being hit AND missing at least 1000 hp.
IC_handle_damage_received :: proc(line: []string) {
	if len(line) < 17 do return
	if line[4] != bot.playerID do return
	state := &bot.state.(ICTimerState)
	if state.asgobas_event do return
	dmg := parse_str_int(line[13])
	if dmg <= 0 do return
	current_hp := parse_str_int(line[16])
	max_hp := parse_str_int(line[17])
	if max_hp - current_hp < 1000 do return
	// log_info(
	// 	fmt.tprintf(
	// 		"[IC] damage taken: -%d hp=%d/%d (missing %d)",
	// 		dmg,
	// 		current_hp,
	// 		max_hp,
	// 		max_hp - current_hp,
	// 	),
	// )
	use_hp_potion()
	if bot.playerID == HOLY_BUFFER_ID {
		IC_cast_buffs(&ic_holy_damage_buffs, "damage")
	}
}

IC_handle_msgi :: proc(words: []string) {
	if words[2] != "384" do return
	state := &bot.state.(ICTimerState)
	if state.asgobas_event {
		//figure something out here later?
	} else {
		walk_safe_spot()
	}
	log_info(
		fmt.tprintf(
			"Round %d ended. DMG: %d, Points: %d, Achieved: %v",
			state.round_number,
			state.current_round,
			state.activation_points,
			state.rewards_achieved,
		),
	)
	state.current_round = 0 //dmg reset round
	state.round_number += 1
	state.activation_points = 0
	state.rewards_achieved = false
}

//packets that start with qnamli
IC_handle_join :: proc(words: []string) {
	state := &bot.state.(ICTimerState)
	if words[2] == "#guri^506" {
		//join ic
		join_packet_1 := "guri 508" //opens the dialog
		join_packet_2 := "#guri^506" // confirm joining
		add_packet_skill_que(500, join_packet_1, true)
		add_packet_skill_que(500, join_packet_2, true)
		log_info("joining ic")
	}
	if words[2] == "#guri^596" {
		// TODO figure out the first packet
		join_packet := "#guri^596"
		add_packet_skill_que(1000, join_packet, true)
		log_info("joining asgobas")
		state := &bot.state.(ICTimerState)
		state.asgobas_event = true
		// qnamli 51 #guri^596 2547 0 0 0 //asgobas join icon
	}
}

IC_handle_su :: proc(line: []string) {
	state := &bot.state.(ICTimerState)
	if len(line) < 17 do return
	if line[1] != "1" {return} 	//1 means damage
	id := line[2]
	dmg_str := line[13]
	dmg := parse_str_int(dmg_str)
	if state.current_round > 0 && id == bot.playerID {
		state.current_round += dmg
		state.activation_points += int(dmg) / (2 * bot.level)
		needed_activation := IC_80_99 * (state.round_number * 3)

		percentage := 0.0
		if needed_activation > 0 {
			percentage = f64(state.activation_points) / f64(needed_activation) * 100.0
		}

		log_info(
			fmt.tprintf(
				"[R%d] DMG: %d (+%d) | Points: %d/%d (%.1f%%)",
				state.round_number,
				state.current_round,
				dmg,
				state.activation_points,
				needed_activation,
				percentage,
			),
		)

		if !state.rewards_achieved && state.activation_points > needed_activation {
			state.rewards_achieved = true
			log_important(
				fmt.tprintf(
					"Achieved round %d points! Points: %d/%d, Total DMG: %d",
					state.round_number,
					state.activation_points,
					needed_activation,
					state.current_round,
				),
			)
		}
	}
}
