package payload

import "core:thread"

main :: proc() {
	thread.create_and_start(actual_main)
}
