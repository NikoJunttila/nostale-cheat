package payload

import "core:log"
import "core:os"
import "core:thread"

main :: proc() {
	thread.create_and_start(actual_main)
}

setup_logger :: proc() -> log.Logger {
	file, err := os.create("logs.txt")
	assert(err == nil)
	return log.create_file_logger(file)
}
