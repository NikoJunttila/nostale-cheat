#+build windows
package payload

// g_entities.odin
//
// Reads entities (monsters/NPCs) and world items (drops) from the game's
// memory, producing the pointer values that are passed to game_attack_monster
// and game_collect.
//
// Memory layout (from offsets_reference.md):
//
//   Entity list:
//     count_base  = ReadPtr(0x003582C0, {0x8, 0x4, 0x60, 0x4, 0x608})
//     list_base   = ReadPtr(0x003566D8, {0xEA4, 0x4, 0x5E4, 0x0})
//     entity_ptr  = *(u32*)(list_base + i*4)          ← pass to game_attack_monster
//     status      = *(u32*)(entity_ptr + 0x08)        -- 0xFFFFFFFF = dead/invalid
//     x           = *(i16*)(entity_ptr + 0x0C)
//     y           = *(i16*)(entity_ptr + 0x0E)
//     name        = cstring(*(u32*)( *(u32*)(entity_ptr + 0x1BC) + 0x04 ))
//
//   Item (drop) list:
//     count_base  = ReadPtr(0x003582C0, {0x8, 0x4, 0x7C, 0x4, 0x568})
//     list_base   = ReadPtr(0x003566D8, {0xEB0, 0x4, 0x5C4, 0x0})
//     item_ptr    = *(u32*)(list_base + i*4)           ← pass to game_collect
//     x           = *(i16*)(item_ptr + 0x0C)
//     y           = *(i16*)(item_ptr + 0x0E)
//     name        = cstring(*(u32*)( *(u32*)(item_ptr + 0xC4) + 0x38 ))
//
//   Player position:
//     pos_base    = ReadPtr(0x004F4904, {0x20, 0x0C})  ← address of player X
//     player_x    = *(i16*)(pos_base)
//     player_y    = *(i16*)(pos_base + 2)
//
// ReadPtr replication (from memscan.c):
//   1. addr = *(u32*)(image_base + base_offset)          [initial deref]
//   2. for each offset except the last: addr = *(u32*)(addr + offset)
//   3. return addr + last_offset                          [final add, NOT deref]

import win "core:sys/windows"
import "core:strings"
import "core:fmt"

// ---------------------------------------------------------------------------
// Safe Memory Reading (Prevents DLL crashes on invalid pointers)
// ---------------------------------------------------------------------------

// safe_deref uses ReadProcessMemory (like the C++ example) which is reliable in
// injected DLL contexts. IsBadReadPtr was deprecated and gave false positives.
safe_deref_u32 :: proc(addr: uintptr, val: ^u32) -> bool {
	bytes_read: win.SIZE_T
	return win.ReadProcessMemory(
		win.GetCurrentProcess(),
		rawptr(addr),
		val,
		4,
		&bytes_read,
	) != win.FALSE && bytes_read == 4
}

safe_deref_i16 :: proc(addr: uintptr, val: ^i16) -> bool {
	bytes_read: win.SIZE_T
	return win.ReadProcessMemory(
		win.GetCurrentProcess(),
		rawptr(addr),
		val,
		2,
		&bytes_read,
	) != win.FALSE && bytes_read == 2
}

// ---------------------------------------------------------------------------
// read_ptr – Walks a pointer chain safely
// ---------------------------------------------------------------------------

// safe_read_ptr – Walks the pointer chain, returns 0 if any step is unmapped/null
safe_read_ptr :: proc(base_offset: uintptr, offsets: []uintptr) -> uintptr {
	mi := getModuleInfo()
	image_base := uintptr(mi.lpBaseOfDll)

	addr: u32
	if !safe_deref_u32(image_base + base_offset, &addr) do return 0
	if addr == 0 do return 0

	for i in 0 ..< len(offsets) - 1 {
		if !safe_deref_u32(uintptr(addr) + offsets[i], &addr) do return 0
		if addr == 0 do return 0
	}

	return uintptr(addr) + offsets[len(offsets) - 1]
}

// debug_read_ptr – same as safe_read_ptr but logs every intermediate step.
// Temporarily swap calls to this to diagnose which step in the chain fails.
debug_read_ptr :: proc(label: string, base_offset: uintptr, offsets: []uintptr) -> uintptr {
	mi := getModuleInfo()
	image_base := uintptr(mi.lpBaseOfDll)
	log_info(fmt.tprintf("[dbg:%s] image_base=%x  reading [%x]", label, image_base, image_base + base_offset))

	addr: u32
	if !safe_deref_u32(image_base + base_offset, &addr) {
		log_info(fmt.tprintf("[dbg:%s] FAIL step0: RPM failed on %x", label, image_base + base_offset))
		return 0
	}
	if addr == 0 {
		log_info(fmt.tprintf("[dbg:%s] FAIL step0: value is null at %x", label, image_base + base_offset))
		return 0
	}
	log_info(fmt.tprintf("[dbg:%s] step0 -> %x", label, addr))

	for i in 0 ..< len(offsets) - 1 {
		next := uintptr(addr) + offsets[i]
		prev := addr
		if !safe_deref_u32(next, &addr) {
			log_info(fmt.tprintf("[dbg:%s] FAIL step%d: RPM failed on [%x+%x]=%x", label, i+1, prev, offsets[i], next))
			return 0
		}
		if addr == 0 {
			log_info(fmt.tprintf("[dbg:%s] FAIL step%d: null at [%x+%x]=%x", label, i+1, prev, offsets[i], next))
			return 0
		}
		log_info(fmt.tprintf("[dbg:%s] step%d (+%x) -> %x", label, i+1, offsets[i], addr))
	}
	result := uintptr(addr) + offsets[len(offsets) - 1]
	log_info(fmt.tprintf("[dbg:%s] final +%x -> %x", label, offsets[len(offsets)-1], result))
	return result
}

// ---------------------------------------------------------------------------
// Entity (monster / NPC)
// ---------------------------------------------------------------------------

Entity :: struct {
	ptr:    u32,   // raw game pointer – pass this to game_attack_monster
	x:      i16,
	y:      i16,
	status: u32,   // 0xFFFFFFFF = dead / invalid
	name:   string,
}

entity_alive :: proc(e: Entity) -> bool {
	return e.ptr != 0 && e.status != 0xFFFFFFFF
}

count_alive_entities :: proc(entities: []Entity) -> int {
	n := 0
	for e in entities {
		if entity_alive(e) do n += 1
	}
	return n
}

// get_entities returns a slice of every valid entity currently in the list.
get_entities :: proc() -> []Entity {

	// DEBUG: verbose logging to find broken offset chain
	list_base  := debug_read_ptr("ent_list",  0x003566D8, []uintptr{0xEA4, 0x4, 0x5E4, 0x0})
	count_base := debug_read_ptr("ent_count", 0x003582C0, []uintptr{0x8, 0x4, 0x60, 0x4, 0x608})

	log_info(fmt.tprintf("[get_entities] list_base: %x count_base: %x", list_base, count_base))

	if list_base == 0 || count_base == 0 do return nil

	raw_count: u32
	if !safe_deref_u32(count_base, &raw_count) {
		log_info("[get_entities] Failed to read count from count_base")
		return nil
	}

	count := int(raw_count) - 1
	log_info(fmt.tprintf("[get_entities] count_base value: %d (count loop size: %d)", raw_count, count))

	if count <= 0 || count > 10000 {
		log_info("[get_entities] Count invalid, returning early")
		return nil
	}

	result := make([dynamic]Entity)

	for i in 0 ..< count {
		ptr: u32
		if !safe_deref_u32(list_base + uintptr(i) * 4, &ptr) do break
		if ptr == 0 {
			// Some slots might legitimately be null if an entity despawns
			continue
		}

		status: u32
		if !safe_deref_u32(uintptr(ptr) + 0x08, &status) {
			continue
		}
		
		ex, ey: i16
		if !safe_deref_i16(uintptr(ptr) + 0x0C, &ex) do continue
		if !safe_deref_i16(uintptr(ptr) + 0x0E, &ey) do continue

		// name: *(u32*)( *(u32*)(ptr + 0x1BC) + 0x04 )
		name_str := ""
		name_chain: u32
		if safe_deref_u32(uintptr(ptr) + 0x1BC, &name_chain) && name_chain != 0 {
			name_ptr: u32
			if safe_deref_u32(uintptr(name_chain) + 0x04, &name_ptr) && name_ptr != 0 {
				// Read up to 255 chars via ReadProcessMemory to avoid a crash on bad string ptr
				buf: [256]byte
				br: win.SIZE_T
				if win.ReadProcessMemory(win.GetCurrentProcess(), rawptr(uintptr(name_ptr)), &buf[0], 255, &br) != win.FALSE && br > 0 {
					buf[br] = 0
					name_str = strings.clone_from_cstring(cast(cstring)&buf[0])
				}
			}
		}

		append(&result, Entity{
			ptr    = ptr,
			x      = ex,
			y      = ey,
			status = status,
			name   = name_str,
		})
	}
	
	log_info(fmt.tprintf("[get_entities] Successfully collected %d entities", len(result)))

	return result[:]
}

// ---------------------------------------------------------------------------
// World Item (drop)
// ---------------------------------------------------------------------------

Item :: struct {
	ptr:  u32,   // raw game pointer – pass this to game_collect
	x:    i16,
	y:    i16,
	name: string,
}

// get_items returns every drop currently visible on the map.
get_items :: proc() -> []Item {
	list_base  := debug_read_ptr("item_list",  0x003566D8, []uintptr{0xEB0, 0x4, 0x5C4, 0x0})
	count_base := debug_read_ptr("item_count", 0x003582C0, []uintptr{0x8, 0x4, 0x7C, 0x4, 0x568})

	log_info(fmt.tprintf("[get_items] list_base: %x count_base: %x", list_base, count_base))

	if list_base == 0 || count_base == 0 do return nil

	raw_count: u32
	if !safe_deref_u32(count_base, &raw_count) {
		log_info("[get_items] Failed to read count from count_base")
		return nil
	}

	count := int(raw_count)
	log_info(fmt.tprintf("[get_items] raw_count = %d", count))

	if count <= 0 || count > 10000 {
		log_info("[get_items] invalid count, returning early")
		return nil
	}

	result := make([dynamic]Item)

	for i in 0 ..< count {
		ptr: u32
		if !safe_deref_u32(list_base + uintptr(i) * 4, &ptr) do continue
		if ptr == 0 do continue

		ix, iy: i16
		if !safe_deref_i16(uintptr(ptr) + 0x0C, &ix) do continue
		if !safe_deref_i16(uintptr(ptr) + 0x0E, &iy) do continue

		// name: *(u32*)( *(u32*)(ptr + 0xC4) + 0x38 )
		name_str := ""
		chain: u32
		if safe_deref_u32(uintptr(ptr) + 0xC4, &chain) && chain != 0 {
			name_ptr: u32
			if safe_deref_u32(uintptr(chain) + 0x38, &name_ptr) && name_ptr != 0 {
				buf: [256]byte
				br: win.SIZE_T
				if win.ReadProcessMemory(win.GetCurrentProcess(), rawptr(uintptr(name_ptr)), &buf[0], 255, &br) != win.FALSE && br > 0 {
					buf[br] = 0
					name_str = strings.clone_from_cstring(cast(cstring)&buf[0])
				}
			}
		}

		append(&result, Item{ptr = ptr, x = ix, y = iy, name = name_str})
	}

	log_info(fmt.tprintf("[get_items] Successfully collected %d items", len(result)))
	return result[:]
}

// ---------------------------------------------------------------------------
// Player position
// ---------------------------------------------------------------------------

PlayerPos :: struct {
	x: i16,
	y: i16,
}

get_player_pos :: proc() -> PlayerPos {
	// ReadPtr(0x004F4904, {0x20, 0x0C}) gives the address of player X
	pos_addr := safe_read_ptr(0x004F4904, []uintptr{0x20, 0x0C})
	if pos_addr == 0 do return {}
	
	px, py: i16
	safe_deref_i16(pos_addr, &px)
	safe_deref_i16(pos_addr + 2, &py)
	
	return PlayerPos{x = px, y = py}
}

// ---------------------------------------------------------------------------
// Distance helper
// ---------------------------------------------------------------------------

chebyshev_dist :: proc(ax, ay, bx, by: i16) -> int {
	dx := int(ax) - int(bx)
	dy := int(ay) - int(by)
	if dx < 0 do dx = -dx
	if dy < 0 do dy = -dy
	if dx > dy do return dx
	return dy
}
