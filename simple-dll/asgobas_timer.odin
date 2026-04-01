package payload

import "core:fmt"
import "core:time"

ASGOBAS_TIMES := [4][2]int{{11, 30}, {17, 30}, {21, 30}, {23, 30}}

// Compute CET/CEST offset without ICU dependency.
// CET = UTC+1, CEST = UTC+2.
// EU DST rules: clocks spring forward last Sunday of March at 01:00 UTC,
//               clocks fall back last Sunday of October at 01:00 UTC.

@(private = "file")
_is_cest :: proc(year, month, day, utc_hour: int) -> bool {
	// Last Sunday of a month: start from day 31 and walk back to find Sunday.
	// time.day_of_week: Sunday=0 for Odin's time package, but we compute manually.
	// Using Tomohiko Sakamoto's day-of-week algorithm (0=Sunday).
	_dow :: proc(y, m, d: int) -> int {
		t := [?]int{0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4}
		y := y
		if m < 3 do y -= 1
		return (y + y / 4 - y / 100 + y / 400 + t[m - 1] + d) % 7
	}

	_last_sunday :: proc(y, m: int) -> int {
		// Find last Sunday of month m in year y
		days_in := [?]int{0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
		last_day := days_in[m]
		if m == 2 && (y % 4 == 0 && (y % 100 != 0 || y % 400 == 0)) do last_day = 29
		dow := _dow(y, m, last_day)
		return last_day - dow
	}

	march_switch := _last_sunday(year, 3)  // last Sunday of March
	october_switch := _last_sunday(year, 10) // last Sunday of October

	// Before March switch day: CET
	if month < 3 do return false
	// After October switch day: CET
	if month > 10 do return false

	if month == 3 {
		if day < march_switch do return false
		if day == march_switch do return utc_hour >= 1
		return true
	}
	if month == 10 {
		if day < october_switch do return true
		if day == october_switch do return utc_hour < 1
		return false
	}
	// April through September: always CEST
	return true
}

asgobas_timer :: proc() {
	now_utc := time.now()

	year, month_enum, day := time.date(now_utc)
	utc_hour, utc_min, utc_sec := time.clock(now_utc)
	month := int(month_enum)

	offset_hours := _is_cest(year, month, day, utc_hour) ? 2 : 1

	// Apply offset (handle day rollover)
	hour := utc_hour + offset_hours
	minute := utc_min
	second := utc_sec
	if hour >= 24 do hour -= 24

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
