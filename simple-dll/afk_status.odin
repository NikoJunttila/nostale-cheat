#+build windows
package payload

import "core:time"


check_afk :: proc() {
	#partial switch bot.mode {
	case .FISHING:
		if check_time(proCastLine.cdTimer, proCastLine.cd) {
			proCastLine.ready = true
		}
		if check_time(maintainLineBuff.cdTimer, maintainLineBuff.cd) {
			maintainLineBuff.ready = true
		}
		if check_time(baitSkill.cdTimer, baitSkill.cd) {
			baitSkill.ready = true
		}
		small_check := time.Second * 20
		if check_time(bot.last_activity, small_check) {
			reset_skill_que()
			fish_note_afk_reset()
			fish_startFishing()
		}
	case .PAUSED, .DPSCheck:
	case .ICE_FLOWER, .MOB_GRINDING, .BUFFING:
	}
}

check_time :: proc(check: time.Time, limit: time.Duration) -> bool {
	time_since := time.diff(check, time.now())
	if time_since > limit {
		return true
	}
	return false
}
