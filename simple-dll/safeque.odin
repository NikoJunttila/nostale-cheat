package payload

import "core:sync"

SafeQueue :: struct {
	mutex: sync.Mutex,
	queue: [dynamic]string,
}

push :: proc(q: ^SafeQueue, packet: string) {
	sync.mutex_lock(&q.mutex)
	defer sync.mutex_unlock(&q.mutex)

	// copy string
	copied := string(packet)

	append(&q.queue, copied)
}

pop :: proc(q: ^SafeQueue) {
	sync.mutex_lock(&q.mutex)
	defer sync.mutex_unlock(&q.mutex)

	if len(q.queue) > 0 {
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

// queue: SafeQueue
//
// push(&queue, "hello")
// push(&queue, "packet2")
//
// packet, ok := front(&queue)
// if ok {
// 	fmt.println(packet)
// }
//
// pop(&queue)
