#+build windows
package payload

import "core:fmt"
import "core:time"

// This is actually the index in inventory not on keybindings
// so first slot in the inventory
BOX_SLOT :: "0"
BOX_SPAMMER_CD :: 500 * time.Millisecond

BoxSpammerState :: struct {
	sent: int,
}

box_spammer_last_use: time.Time

handle_box_spammer_packet :: proc(words: []string) {
	switch words[0] {
	case "c_map":
		handleC_map(words)
	case "in":
		handleIN(words)
	}
}

// Periodic tick — fires u_i for the configured inventory slot every BOX_SPAMMER_CD.
BoxSpammer_tick :: proc() {
	if !check_time(box_spammer_last_use, BOX_SPAMMER_CD) do return
	packet := fmt.aprintf("u_i 1 %s 1 %s 0 0", bot.playerID, BOX_SLOT)
	send_packet(packet)
	delete(packet)
	box_spammer_last_use = time.now()
	state := &bot.state.(BoxSpammerState)
	state.sent += 1
}
