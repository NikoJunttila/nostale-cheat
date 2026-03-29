# Nostale_Bot: Memory Offsets & Patterns Reference

This document lists all the memory addresses, pointer chains, and binary patterns used by the bot to interact with the game. These are essential for porting the logic to another language like Odin.

## 1. Player Data

| Feature | Base Address | Offset Chain | Data Type | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **Position Pointer** | `0x004F4904` | `{ 0x20, 0x0C }` | `rawptr` | Base address for X/Y |
| **- Player X** | `[PosPtr]` | `+0x00` | `i16` | |
| **- Player Y** | `[PosPtr]` | `+0x02` | `i16` | |
| **Stats Pointer** | `0x004F4BA8` | `{ 0xE4, 0x100, 0x4C8, 0x8B8 }` | `rawptr` | Base for HP/MP |
| **- Max MP** | `[StatsPtr]` | `+0x00` | `u32` | |
| **- Current MP** | `[StatsPtr]` | `+0x04` | `u32` | |
| **- Max HP** | `[StatsPtr]` | `+0xF0` | `u32` | |
| **- Current HP** | `[StatsPtr]` | `+0xF4` | `u32` | |
| **Range** | `0x004F4904` | `{ 0x68 }` | `u8` | Attack/Loot distance |

## 2. Entities (Monsters & NPCs)

- **Counter**: [ReadPointer(0x003582C0, { 0x8, 0x4, 0x60, 0x4, 0x608 })](file:///home/derp/docker/windows/shared/Nostale_Bot/memscan.c#25-39)
- **List Base**: [ReadPointer(0x003566D8, { 0xEA4, 0x4, 0x5E4, 0x0 })](file:///home/derp/docker/windows/shared/Nostale_Bot/memscan.c#25-39)
- **Entity Entry**: `[ListBase] + (index * 0x04)`

| Field | Offset Chain | Data Type | Notes |
| :--- | :--- | :--- | :--- |
| **Status/Valid** | `+0x08` | `u32` | `0xFFFFFFFF` usually means dead/invalid |
| **X Coordinate** | `+0x0C` | `i16` | |
| **Y Coordinate** | `+0x0E` | `i16` | |
| **Name String** | `[[Entity] + 0x1BC] + 0x04` | `cstring` | Pointer to the name string |

## 3. World Items (Drops)

- **Counter**: [ReadPointer(0x003582C0, { 0x8, 0x4, 0x7C, 0x4, 0x568 })](file:///home/derp/docker/windows/shared/Nostale_Bot/memscan.c#25-39)
- **List Base**: [ReadPointer(0x003566D8, { 0xEB0, 0x4, 0x5C4, 0x0 })](file:///home/derp/docker/windows/shared/Nostale_Bot/memscan.c#25-39)
- **Item Entry**: `[ListBase] + (index * 0x04)`

| Field | Offset Chain | Data Type | Notes |
| :--- | :--- | :--- | :--- |
| **X Coordinate** | `+0x0C` | `i16` | |
| **Y Coordinate** | `+0x0E` | `i16` | |
| **Name String** | `[[Item] + 0xC4] + 0x38` | `cstring` | Pointer to the name string |

## 4. Skills & Cooldowns

- **Skill List**: [ReadPointer(0x004C3E5C, { 0x1BC, 0xF0, 0x0, 0x170, 0x7F4 })](file:///home/derp/docker/windows/shared/Nostale_Bot/memscan.c#25-39)
- **CD Base 1**: [ReadPointer(0x004F4DD0, { 0x158, 0x4, 0x4, 0x0, 0x24 })](file:///home/derp/docker/windows/shared/Nostale_Bot/memscan.c#25-39)
- **CD Base 2**: [ReadPointer(0x004F4CDC, { 0x20, 0x4, 0x88, 0xE28, 0x24 })](file:///home/derp/docker/windows/shared/Nostale_Bot/memscan.c#25-39)

| Field | Offset Calculation | Data Type | Notes |
| :--- | :--- | :--- | :--- |
| **Cooldown** | `[CDBase] + (skillIndex - 1) * 0x48` | `u32` | `0` = Ready to use |
| **Skill Name** | `[SkillList] + (index * 0x2A0)` | `cstring` | Entry size is `0x2A0` |

## 5. Function Patterns (AOBs)

These patterns are used to find the addresses of the game's internal functions.

| Function | Pattern (HEX) | Mask |
| :--- | :--- | :--- |
| **Move** | `55 8B EC 83 C4 00 53 56 57 66 89 00 00 89 55` | `xxxxx?xxxxx??xx` |
| **Attack** | `6A 00 6A 00 6A 00 E8 00 00 00 00 C3 55` | `x?x?x?x????xx` |
| **Collect** | `55 8B EC ... 68 00 00 00 00 64 FF 00 64 89 00 A1` | `xxxx?x?x?x?xxxxxxxxxx????xx?xx?x` |
| **Rest** | `55 8B EC B9 00 00 00 00 6A 00 6A 00 49 75 00 51 ...` | `xxxx????x?x?xx?xxxxxx` |
| **Attack Run** | `55 8B EC 51 53 56 57 88 4D 00 8B F2 8B F8` | `xxxxxxxxx?xxxx` |

## 6. Static This-Pointers (Constants)

| Variable | Address | Notes |
| :--- | :--- | :--- |
| `lpvAttackThis` | `0x008F4904` | Used in `AttackMonster` |
| `lpvMoveThis` | `0x008F4904` | Used in [MoveTo](file:///home/derp/docker/windows/shared/Nostale_Bot/CallFunction.c#56-132) |
| `lpvCollectThis` | `0x00765EA8` | Used in `Collect` |
| `characterPointer`| `0x00360E7C` | Global character base |
