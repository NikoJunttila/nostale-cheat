package simple_dll
// import "core:fmt"
// import win "core:sys/windows"
//
// import "core:time"
//
// get_base :: proc() -> uintptr {
// 	base := uintptr(win.GetModuleHandleA(nil))
// 	fmt.println("Base handle:", base)
// 	return base
// }
//
// get_player_base :: proc() -> uintptr {
// 	if exe_base == 0 do return 0
// 	// The player base pointer is at exe_base + ENTITY_BASE_OFFSET
// 	ptr_to_player := (^uintptr)(exe_base + ENTITY_BASE_OFFSET)
// 	player_base = ptr_to_player^
// 	fmt.println("Player base:", player_base)
// 	return player_base
// }
//
// inf_hp_ammo_loop :: proc(cfg: ^Config) {
// 	fmt.println("Starting infinite HP/Ammo loop...")
// 	for {
// 		time.sleep(time.Duration(cfg.update_interval_ms) * time.Millisecond)
//
// 		if player_base == 0 {
// 			get_player_base()
// 			if player_base == 0 do continue
// 		}
//
// 		// Direct memory access - dereferencing pointers to update values
// 		hp_ptr := (^i32)(player_base + HEALTH_OFFSET)
// 		if hp_ptr^ != cfg.target_health {
// 			hp_ptr^ = cfg.target_health
// 		}
//
// 		ammo_ptr := (^i32)(player_base + ASSAULT_RIFLE_AMMO_OFFSET)
// 		if ammo_ptr^ != cfg.target_ammo {
// 			ammo_ptr^ = cfg.target_ammo
// 		}
// 	}
// }
