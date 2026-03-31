package payload

import "core:fmt"
import "core:time"
import "core:time/datetime"
import "core:time/timezone"

ASGOBAS_TIMES := [4][2]int{{11, 30}, {17, 30}, {21, 30}, {23, 30}}

asgobas_timer :: proc() {
	tz, ok := timezone.region_load("Europe/Berlin", context.allocator)
	if !ok {
		log_error("failed to load timezone")
		return
	}

	now_utc := time.now()

	now_dt, ok2 := time.time_to_datetime(now_utc)
	if !ok2 {
		log_error("failed to convert current time to datetime")
		return
	}

	local_dt, ok3 := timezone.datetime_to_tz(now_dt, tz)
	if !ok3 {
		log_error("failed to convert datetime to timezone")
		return
	}

	hour := int(local_dt.time.hour)
	minute := int(local_dt.time.minute)
	second := int(local_dt.time.second)

	log_info(fmt.tprintf("Local CET/CEST time: %02d:%02d:%02d", hour, minute, second))

	now_seconds := hour * 3600 + minute * 60 + second

	next_hour := 0
	next_minute := 0
	diff_seconds := -1

	for t in ASGOBAS_TIMES {
		target_seconds := t[0] * 3600 + t[1] * 60
		if target_seconds > now_seconds {
			next_hour = t[0]
			next_minute = t[1]
			diff_seconds = target_seconds - now_seconds
			break
		}
	}

	// If today's last spawn already passed, next one is tomorrow at 11:30
	if diff_seconds < 0 {
		next_hour = ASGOBAS_TIMES[0][0]
		next_minute = ASGOBAS_TIMES[0][1]
		target_seconds := next_hour * 3600 + next_minute * 60
		diff_seconds = (24 * 3600 - now_seconds) + target_seconds
	}

	diff_hours := diff_seconds / 3600
	diff_mins := (diff_seconds % 3600) / 60
	diff_secs := diff_seconds % 60

	log_info(fmt.tprintf("Next Asgobas: %02d:%02d CET/CEST", next_hour, next_minute))
	log_info(fmt.tprintf("Time until next Asgobas: %dh %dm %ds", diff_hours, diff_mins, diff_secs))
}
