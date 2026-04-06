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

import "core:strings"

// ---------------------------------------------------------------------------
// read_ptr – identical logic to the C++ ReadPointer in memscan.c
// ---------------------------------------------------------------------------

read_ptr :: proc(base_offset: uintptr, offsets: []uintptr) -> uintptr {
	mi := getModuleInfo()
	image_base := uintptr(mi.lpBaseOfDll)

	// Step 1: add image base then dereference
	addr := uintptr((cast(^u32)(image_base + base_offset))^)

	// Step 2: walk all offsets except the last, dereferencing at each step
	for i in 0 ..< len(offsets) - 1 {
		addr = uintptr((cast(^u32)(addr + offsets[i]))^)
	}

	// Step 3: add final offset (not dereferenced)
	return addr + offsets[len(offsets) - 1]
}

// safe_read_ptr – like read_ptr but returns 0 on null pointer at any step
safe_read_ptr :: proc(base_offset: uintptr, offsets: []uintptr) -> uintptr {
	mi := getModuleInfo()
	image_base := uintptr(mi.lpBaseOfDll)

	addr := uintptr((cast(^u32)(image_base + base_offset))^)
	if addr == 0 do return 0

	for i in 0 ..< len(offsets) - 1 {
		addr = uintptr((cast(^u32)(addr + offsets[i]))^)
		if addr == 0 do return 0
	}

	return addr + offsets[len(offsets) - 1]
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
// The caller owns the returned slice (call delete() when done).
// Max 256 entries is a safe upper bound for Nostale maps.
get_entities :: proc() -> []Entity {
	list_base  := read_ptr(0x003566D8, []uintptr{0xEA4, 0x4, 0x5E4, 0x0})
	count_base := read_ptr(0x003582C0, []uintptr{0x8, 0x4, 0x60, 0x4, 0x608})

	if list_base == 0 || count_base == 0 do return nil

	count := int((cast(^u32)(count_base))^) - 1
	if count <= 0 || count > 256 do return nil

	result := make([dynamic]Entity)

	for i in 0 ..< count {
		ptr := (cast(^u32)(list_base + uintptr(i) * 4))^
		if ptr == 0 do break

		status := (cast(^u32)(uintptr(ptr) + 0x08))^
		ex     := (cast(^i16)(uintptr(ptr) + 0x0C))^
		ey     := (cast(^i16)(uintptr(ptr) + 0x0E))^

		// name: *(u32*)( *(u32*)(ptr + 0x1BC) + 0x04 )
		name_chain := (cast(^u32)(uintptr(ptr) + 0x1BC))^
		name_str   := ""
		if name_chain != 0 {
			name_ptr := (cast(^u32)(uintptr(name_chain) + 0x04))^
			if name_ptr != 0 {
				name_str = strings.clone_from_cstring(cast(cstring)rawptr(uintptr(name_ptr)))
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
// The caller owns the returned slice.
get_items :: proc() -> []Item {
	list_base  := read_ptr(0x003566D8, []uintptr{0xEB0, 0x4, 0x5C4, 0x0})
	count_base := read_ptr(0x003582C0, []uintptr{0x8, 0x4, 0x7C, 0x4, 0x568})

	if list_base == 0 || count_base == 0 do return nil

	count := int((cast(^u32)(count_base))^)
	if count <= 0 || count > 256 do return nil

	result := make([dynamic]Item)

	for i in 0 ..< count {
		ptr := (cast(^u32)(list_base + uintptr(i) * 4))^
		if ptr == 0 do continue

		ix := (cast(^i16)(uintptr(ptr) + 0x0C))^
		iy := (cast(^i16)(uintptr(ptr) + 0x0E))^

		// name: *(u32*)( *(u32*)(ptr + 0xC4) + 0x38 )
		name_str := ""
		chain := (cast(^u32)(uintptr(ptr) + 0xC4))^
		if chain != 0 {
			name_ptr := (cast(^u32)(uintptr(chain) + 0x38))^
			if name_ptr != 0 {
				name_str = strings.clone_from_cstring(cast(cstring)rawptr(uintptr(name_ptr)))
			}
		}

		append(&result, Item{ptr = ptr, x = ix, y = iy, name = name_str})
	}

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
	pos_addr := read_ptr(0x004F4904, []uintptr{0x20, 0x0C})
	if pos_addr == 0 do return {}
	return PlayerPos{
		x = (cast(^i16)(pos_addr))^,
		y = (cast(^i16)(pos_addr + 2))^,
	}
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
