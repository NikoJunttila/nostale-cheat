package payload
//
import "core:time"
import win "core:sys/windows"

LOG_BUFFER_SIZE :: 512
LOG_PREFIX_INFO  :: "[PAYLOAD] INFO: "
LOG_PREFIX_WARN  :: "[PAYLOAD] WARN: "
LOG_PREFIX_ERROR :: "[PAYLOAD] ERROR: "

VERSION :: "1.0.92"

log_info :: proc(message: string) {
	log_with_prefix(LOG_PREFIX_INFO, message)
}

log_warn :: proc(message: string) {
	log_with_prefix(LOG_PREFIX_WARN, message)
}

log_error :: proc(message: string) {
	log_with_prefix(LOG_PREFIX_ERROR, message)
}

log_with_prefix :: proc(prefix, message: string) {
	hour, min, sec := time.clock_from_time(time.now())

	buffer: [LOG_BUFFER_SIZE]u8

	// Write HH:MM:SS timestamp manually into buffer
	written := 0
	write_2digit :: proc(buf: []u8, offset: int, val: int) -> int {
		buf[offset]     = u8('0' + val / 10)
		buf[offset + 1] = u8('0' + val % 10)
		return 2
	}
	buffer[written] = '['; written += 1
	written += write_2digit(buffer[:], written, hour)
	buffer[written] = ':'; written += 1
	written += write_2digit(buffer[:], written, min)
	buffer[written] = ':'; written += 1
	written += write_2digit(buffer[:], written, sec)
	buffer[written] = ']'; written += 1
	buffer[written] = ' '; written += 1

	written += safe_copy(buffer[:], "[v", written)
	written += safe_copy(buffer[:], VERSION, written)
	written += safe_copy(buffer[:], "] ", written)
	written += safe_copy(buffer[:], prefix, written)
	written += safe_copy(buffer[:], message, written)
	if written > LOG_BUFFER_SIZE - 2 {
		written = LOG_BUFFER_SIZE - 2
	}
	buffer[written]     = '\n'
	buffer[written + 1] = 0
	win.OutputDebugStringA(cast(win.LPCSTR)&buffer[0])
}

safe_copy :: proc(dst: []u8, src: string, offset: int) -> int {
	if offset >= len(dst) - 1 {
		return 0
	}
	src_bytes := transmute([]byte)src
	remaining := len(dst) - offset - 1
	count := len(src_bytes)
	if count > remaining {
		count = remaining
	}
	copy(dst[offset:], src_bytes[:count])
	return count
}
