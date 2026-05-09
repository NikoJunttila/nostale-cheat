#+build windows
package payload

import "core:slice"
import "core:strconv"
import "core:strings"

raid_player :: struct {
	name: string,
	dmg:  i32,
}

DPSCheckState :: struct {
	sorted_raid_list: [dynamic]raid_player,
	raid_list:        map[string]raid_player,
	total_dmg:        i32,
}

handle_DPSCheck_packet :: proc(words: []string) {
	switch words[0] {
	case "su":
		DPS_handleSU(words)
	case "c_map":
		handleC_map(words)
	case "in":
		handleIN(words)
	}
}

DPS_handleSU :: proc(line: []string) {
	state := &bot.state.(DPSCheckState)
	if len(line) < 17 do return
	if line[1] != "1" {return} 	//1 means damage
	id := line[2]
	dmg_str := line[13]
	dmg := parse_str_int(dmg_str)
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

DPS_reset_raid_list :: proc(state: ^DPSCheckState) {
	for key, _ in state.raid_list {
		delete(key) // Free the cloned string
	}
	delete(state.raid_list)
	state.raid_list = make(map[string]raid_player)
}

// Internal proc to rebuild and sort the list (limited to top 20)
DPS_rebuild_sorted_list :: proc(state: ^DPSCheckState) {
	MAX_DISPLAY :: 15

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
		return 0
	}
	return i32(dmg)
}
