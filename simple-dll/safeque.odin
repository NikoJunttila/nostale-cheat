package payload

import "core:strings"
import "core:sync"

SafeQueue :: struct {
	mutex: sync.Mutex,
	queue: [dynamic]string,
}

push :: proc(q: ^SafeQueue, packet: string) {
	sync.mutex_lock(&q.mutex)
	defer sync.mutex_unlock(&q.mutex)

	// Clone the string data so we own it — string(packet) is NOT a copy,
	// it's a reinterpret of the game's packet buffer which gets overwritten.
	cloned := strings.clone(packet)
	append(&q.queue, cloned)
}

pop :: proc(q: ^SafeQueue) {
	sync.mutex_lock(&q.mutex)
	defer sync.mutex_unlock(&q.mutex)

	if len(q.queue) > 0 {
		delete(q.queue[0]) // free the cloned string memory
		ordered_remove(&q.queue, 0)
	}
}

front :: proc(q: ^SafeQueue) -> (string, bool) {
	sync.mutex_lock(&q.mutex)
	defer sync.mutex_unlock(&q.mutex)

	if len(q.queue) == 0 {
		return "", false
	}

	return q.queue[0], true
}

empty :: proc(q: ^SafeQueue) -> bool {
	sync.mutex_lock(&q.mutex)
	defer sync.mutex_unlock(&q.mutex)

	return len(q.queue) == 0
}
