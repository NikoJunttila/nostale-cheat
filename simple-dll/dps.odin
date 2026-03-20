#+build windows
package payload

import "core:fmt"
import "core:slice"
import "core:strconv"
import "core:strings"

/*
Threshold (in action points) go as follows: x, 3*x, 6*x, 10*x

IC 1-39: its 37.5, so 37.5, 37.5*3, 37.5*6, 37.5*10
IC 40-49 and 50-59: its 75, so 75, 225, 450, 750
IC 60-69 and 70-79: its 112.5. so [...]
IC 80-99: its 150, so 150, 450, 900, 1500 */
IC_80_99 :: 150
//combine ic and asgobas?
DPSMode :: enum {
	IC, // + ascobas
	RAID, //cound all damages and sort by most dmg done? List of all raid boss ids needed to count damage on boss
}

raid_player :: struct {
	name: string,
	dmg:  i32,
}


DPSCheckState :: struct {
	mode:              DPSMode,
	total_dmg:         i32,
	boss_dmg:          i32,
	boss_hp:           i32,
	current_round:     i32, //damage
	round_number:      int,
	activation_points: int,
	rewards_achieved:  bool,
	afk_ic:            bool,
	raid_list:         map[string]raid_player,
	sorted_raid_list:  [dynamic]raid_player,
}
handle_DPSCheck_packet :: proc(words: []string) {
	switch words[0] {
	case "qnamli":
		DPS_handle_join(words)
	case "msgi":
		DPS_handle_msgi(words)
	case "su":
		DPS_handleSU(words)
	case "c_map":
		handleC_map(words)
	case "in":
		handleIN(words)
	}
}

DPS_handle_msgi :: proc(words: []string) {
	if words[2] == "384" {
		state := &bot.state.(DPSCheckState)
		log_info(fmt.tprintf("new round dmg: %d", state.current_round))
		state.current_round = 0 //reset round
		state.round_number += 1
		state.activation_points = 0
		state.rewards_achieved = false
	}
}

//packets that start with gnamli
DPS_handle_join :: proc(words: []string) {
	state := &bot.state.(DPSCheckState)
	#partial switch state.mode {
	case .IC:
		if words[2] == "#guri^506" {
			//join ic
			join_packet := "#guri^506"
			log_info("should join ic here")
			add_packet_skill_que(2000, join_packet, true)
			state.current_round = 0 //dmg
			state.round_number = 0
			state.activation_points = 0
		}
		if words[2] == "#guri^596" {
			//join ascobas
			join_packet := "#guri^596"
			log_info("should join ascobas here")
			add_packet_skill_que(2000, join_packet, true)
			state.current_round = 0 //dmg
			state.round_number = 0
			state.activation_points = 0
		}
	// qnamli 51 #guri^596 2547 0 0 0 //asgobas join icon
	}
}

// moved_to_ic :: proc() {
// 	mv_packet := "walk 40 68 0 15"
// 	add_packet_skill_que(1000, mv_packet) //walk to safespot
// 	// tp_packet := fmt.aprintf("0 tp 1 %s 40 68", bot.playerID) //recv tp to fake you at safespot?
// 	// add_packet_skill_que(mv_packet)
// 	// delete(tp_packet)
// }


DPS_handleSU :: proc(line: []string) {
	state := &bot.state.(DPSCheckState)
	if len(line) < 17 do return
	if line[1] != "1" {return} 	//1 means damage
	id := line[2]
	dmg_str := line[13]
	dmg := parse_str_int(dmg_str)
	if state.mode != .RAID && id == bot.playerID {
		state.total_dmg += dmg
		switch state.mode {
		case .IC:
			state.current_round += dmg
			state.activation_points += int(dmg) / (2 * bot.level)
			needed_activation := IC_80_99 * (state.round_number * 3)
			if state.activation_points >= needed_activation && needed_activation > 0 {
				state.rewards_achieved = true
				log_important("achieved round points")
				log_info(fmt.tprintf("dmg: %d", state.current_round))
			}
		case .RAID:
		}
	} else {
		player, ok := state.raid_list[id]
		idInt := parse_str_int(id)
		name, nOK := bot.player_list[idInt]
		if !nOK do name = "Unknown"
		if id == bot.playerID do name = "YOU!!!"
		if ok {
			player.dmg += dmg
			player.name = name
			state.raid_list[id] = player // reinsert updated struct
		} else {
			onHeap := strings.clone(id, context.allocator) //another mem leak
			state.raid_list[onHeap] = raid_player {
				name = name,
				dmg  = dmg,
			}
		}
		DPS_rebuild_sorted_list(state)
	}
}

DPS_reset_raid_list :: proc(state: ^DPSCheckState) {
	for key, _ in state.raid_list {
		delete(key) // Free the cloned string
	}
	delete(state.raid_list)
	state.raid_list = make(map[string]raid_player)
}

// Internal proc to rebuild and sort the list (limited to top 20)
DPS_rebuild_sorted_list :: proc(state: ^DPSCheckState) {
	MAX_DISPLAY :: 20

	// Clear existing sorted list
	clear(&state.sorted_raid_list)

	// Rebuild from map
	for id, player in state.raid_list {
		append(&state.sorted_raid_list, raid_player{name = player.name, dmg = player.dmg})
	}

	// Sort by damage descending
	slice.sort_by(state.sorted_raid_list[:], proc(i, j: raid_player) -> bool {
		return i.dmg > j.dmg
	})

	// Trim to top 20 if we have more
	if len(state.sorted_raid_list) > MAX_DISPLAY {
		resize(&state.sorted_raid_list, MAX_DISPLAY)
	}
}

parse_str_int :: proc(str: string) -> i32 {
	dmg_str := str
	dmg, ok := strconv.parse_int(dmg_str)
	if !ok {
		fmt.println("failed to parse ", dmg_str)
		return 0
	}
	return i32(dmg)
}
