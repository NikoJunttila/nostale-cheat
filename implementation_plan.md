# Porting Nostale_Bot to Odin

This plan outlines the steps to rewrite the Nostale_Bot in the **Odin** programming language, using **odin-imgui** for the interface and native Odin threading for the bot logic.

## Technical Strategy: Handling Assembly in Odin

In the C++ project, MSVC’s `_asm` blocks were used. Odin handles this differently:

### 1. Register Loading with `asm`
Odin (via its LLVM backend) supports inline assembly blocks. To replicate the `AttackMonster` logic where `EAX`, `EDX`, and `CX` must be specifically loaded, you would write:

```odin
attack_monster_internal :: proc(target: rawptr, skill: u16, this_ptr: rawptr, func_ptr: rawptr) {
    // LLVM-style assembly to load registers and call
    asm(target, skill, this_ptr, func_ptr) {
        "mov edx, $0",
        "mov cx,  $1",
        "mov eax, $2",
        "call $3",
        "r" (target), "r" (skill), "r" (this_ptr), "r" (func_ptr),
        "eax", "edx", "ecx" // Clobbers
    }
}
```

### 2. "Naked" Function Wrappers
A **Naked function** is one that contains no compiler-generated code (no stack setup). This is useful if you want to write a pure assembly stub and jump to it. In Odin, you generally achieve this by using the `asm` block inside a procedure marked with `#force_inline` to avoid stack overhead.

---

## Proposed Changes

### [Component] Core Infrastructure
#### [NEW] main.odin
The DLL entry point using Odin's `_dll_main`. This will spawn the initialization thread.
#### [NEW] g_mem.odin
Porting the [ReadPointer](file:///home/derp/docker/windows/shared/Nostale_Bot/memscan.h#6-7) and [FindPattern](file:///home/derp/docker/windows/shared/Nostale_Bot/memscan.c#3-24) functions from [memscan.c](file:///home/derp/docker/windows/shared/Nostale_Bot/memscan.c) using Odin's `core:mem` and `core:sys/windows`.

### [Component] Game Interaction
#### [NEW] g_functions.odin
Implementation of all internal game wrappers (`move_to`, [attack](file:///home/derp/docker/windows/shared/Nostale_Bot/gui.h#67-68), [collect](file:///home/derp/docker/windows/shared/Nostale_Bot/gui.h#64-65)) using the assembly techniques described above.

### [Component] GUI Layer
#### [NEW] gui.odin
Setting up **odin-imgui**. Since this is a DLL injection, you will need to:
1. Hook the game's **DirectX 9/11 SwapChain** (Present function) to render the GUI.
2. Initialize ImGui inside the hook.
3. Draw the tabs corresponding to the original project.

### [Component] Bot Logic
#### [NEW] bot.odin
The core loops for Walker, Healer, and Target bots. This will use:
- `core:thread` for background processing.
- `core:time` for delays and timers.
- A global `BotState` struct to store configurations.

---

## Verification Plan

### Automated Steps
- **Memory Tests**: Validate that [ReadPointer](file:///home/derp/docker/windows/shared/Nostale_Bot/memscan.h#6-7) returns the same addresses in Odin as it did in the C++ version.
- **Pattern Match**: Verify that the AOB scanning logic correctly identifies the function addresses.

### Manual Verification
- **GUI Test**: Inject the Odin DLL and verify that the ImGui window appears correctly over the game.
- **Action Test**: Trigger a "MoveTo" action from the Odin GUI and verify the character moves in-game.
