#+build windows
package payload

import "core:fmt"

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
	asgobas_round:     bool,
}

handle_ic_timer_packet :: proc(words: []string) {
	switch words[0] {
	case "qnamli":
		IC_handle_join(words)
	case "msgi":
		IC_handle_msgi(words)
	case "su":
		IC_handle_su(words)
	case "c_map":
		handleC_map(words)
	case "in":
		handleIN(words)
	}
}

IC_handle_msgi :: proc(words: []string) {
	if words[2] == "384" {
		state := &bot.state.(ICTimerState)
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
}

//packets that start with qnamli
IC_handle_join :: proc(words: []string) {
	state := &bot.state.(ICTimerState)
	if words[2] == "#guri^506" {
		//join ic
		state.current_round = 0 //dmg
		state.round_number = 0
		state.activation_points = 0
	}
	if words[2] == "#guri^596" {
		//join ascobas
		state.current_round = 0 //dmg
		state.round_number = 0
		state.activation_points = 0
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
