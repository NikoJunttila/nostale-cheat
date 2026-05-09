walk packet to safespot in ic
walks user. only other people see user walking but not us.
send: walk 35 14 1 12
walk 35 68 1 16 // actual IC spot
send client side to show where we are
receive: tp 1 8141324 46 7 0

---------------------------------------------------------------------------------

zip injector + dll + sound + example.json + guide. when making this possible for other to use also

---------------------------------------------------------------------------

take the main player id from json also instead of hardcoded in buffers

-------------------------------------------------------------------------

/home/derp/docker/windows/shared/nostale-cheats/example-Nostale_Bot/NostaleClientX.CT

FIND NEW OFFSETS for moblist and item list

This is very clear. Both chains are confirmed stale — the base offsets no longer point to global variables:

ent_list step0 returned 0x6a006a01 — those are x86 opcodes (PUSH 0 / PUSH 1), you're reading code bytes, not a pointer. 0x3566D8 now lands in executable code.
ent_count step0 returned 3 — not a pointer at all. 0x3582C0 is similarly garbage.
image_base=400000 ✅ — that's correct, so getModuleInfo() is fine.

The game was updated and both static global addresses have moved. You need to find the new values with Cheat Engine.

How to find the new offsets in Cheat Engine
The original C++ code reads:

c
ReadPointer(0x003566D8, {0xEA4, 0x4, 0x5E4, 0x0})   // entity list
ReadPointer(0x003582C0, {0x8, 0x4, 0x60, 0x4, 0x608}) // entity count
0x3566D8 and 0x3582C0 are static offsets from image base to a global pointer variable in the EXE. You need to find what those static addresses are now.

Step-by-step in Cheat Engine
1. Open the existing CT file (

NostaleClientX.CT
) — it may still have pointer chain entries. Check if any entries labelled "entity list" or "monster count" still work. If they do, right-click → "Find out what accesses this address" to get the static base.

2. If CT file entries are broken, find the entity count fresh:

Log in to game, go to a map with monsters visible
In CE: scan for the count of visible monsters as 4-byte value
Kill one → "Decreased value" scan
Repeat until you isolate the count address
Right-click the found address → "Pointer scan for this address"
In pointer scan settings: max offset 0x800, max depth 5, check "Only find paths with static base"
Look for results that start with an offset from NostaleClientX.exe (shown as NostaleClientX.exe+XXXXXX) — that XXXXXX is the new count_base static offset
3. For the entity list pointer — once you have a valid entity object address:

Right-click → pointer scan
Same settings, look for the static base path
The offsets in the chain are the new {0xEA4, 0x4, 0x5E4, 0x0} equivalents
Once you have both new static addresses, update in 

g_entities.odin
:

odin
list_base  := debug_read_ptr("ent_list",  0xNEW_OFFSET, []uintptr{...new offsets...})
count_base := debug_read_ptr("ent_count", 0xNEW_OFFSET, []uintptr{...new offsets...})
The inner offsets (0xEA4, 0x5E4, etc.) might still be valid — only the static base addresses are confirmed broken. Try the old inner offsets first with the new base addresses.



