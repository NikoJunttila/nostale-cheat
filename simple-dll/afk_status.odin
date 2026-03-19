#+build windows
package payload

import "core:time"


check_afk :: proc() {
	switch bot.mode {
	case .FISHING:
		fishing_state := &bot.state.(FishingState)
		buff_cd := time.Minute * 2 + time.Second * 5
		proline_buff_cd := time.Minute + time.Second * 5
		if check_time(fishing_state.proCastLineCD, proline_buff_cd) {
			fishing_state.proCastLine = true
		}
		if check_time(fishing_state.lineCast, buff_cd) {
			fishing_state.lineBuff = true
		}
		if check_time(fishing_state.baitCast, buff_cd) {
			fishing_state.baitSkill = true
		}
		small_check := time.Second * 20
		if check_time(bot.last_activity, small_check) {
			reset_skill_que()
			fish_startFishing()
		}
	case .PAUSED, .DPSCheck:
	case .ICE_FLOWER, .MOB_GRINDING:
	}
}

check_time :: proc(check: time.Time, limit: time.Duration) -> bool {
	time_since := time.diff(check, time.now())
	if time_since > limit {
		return true
	}
	return false
}
