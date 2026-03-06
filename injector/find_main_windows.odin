package injector

import "base:runtime"
import "core:fmt"
import "core:strings"
import "core:sys/windows"

// Check if process has a main window with game title
has_game_window :: proc(pid: u32) -> bool {
	// Create a context structure to pass data in and out
	Context :: struct {
		target_pid: u32,
		found:      bool,
	}

	ctx := Context {
		target_pid = pid,
		found      = false,
	}

	enum_windows_callback :: proc "stdcall" (
		hwnd: windows.HWND,
		lparam: windows.LPARAM,
	) -> windows.BOOL {
		context = runtime.default_context()

		// Cast lparam: LPARAM -> uintptr -> pointer
		ctx := cast(^Context)uintptr(lparam)

		window_pid: u32
		windows.GetWindowThreadProcessId(hwnd, &window_pid)

		if window_pid == ctx.target_pid {
			if windows.IsWindowVisible(hwnd) {
				// Get window title
				title_buf: [256]u16
				length := windows.GetWindowTextW(hwnd, &title_buf[0], 256)
				if length > 0 {
					// Convert title to string for checking
					title_slice := title_buf[:length]
					title, err := windows.utf16_to_utf8(title_slice, context.temp_allocator)
					if err == nil {
						fmt.println("Found window with title:", title)

						// Check if title contains game-specific text
						// For example, if the game window has "NosTale" in the title:
						if strings.contains(title, "NosTale") {
							ctx.found = true
							return false // Stop enumeration
						}
					}
				}
			}
		}
		return true // Continue enumeration
	}

	// Cast pointer: pointer -> uintptr -> LPARAM
	windows.EnumWindows(enum_windows_callback, windows.LPARAM(uintptr(&ctx)))
	return ctx.found
}

get_process_memory_usage :: proc(pid: u32) -> u64 {
	handle := windows.OpenProcess(
		windows.PROCESS_QUERY_INFORMATION | windows.PROCESS_VM_READ,
		false,
		pid,
	)
	if handle == nil do return 0
	defer windows.CloseHandle(handle)

	pmc: windows.PROCESS_MEMORY_COUNTERS
	pmc.cb = size_of(windows.PROCESS_MEMORY_COUNTERS)

	if windows.K32GetProcessMemoryInfo(handle, &pmc, pmc.cb) {
		return u64(pmc.WorkingSetSize)
	}
	return 0
}
//
has_graphics_dlls :: proc(pid: u32) -> bool {
	handle := windows.OpenProcess(
		windows.PROCESS_QUERY_INFORMATION | windows.PROCESS_VM_READ,
		false,
		pid,
	)
	if handle == nil do return false
	defer windows.CloseHandle(handle)

	modules: [1024]windows.HMODULE
	needed: u32

	if windows.K32EnumProcessModules(handle, &modules[0], size_of(modules), &needed) {
		module_count := needed / size_of(windows.HMODULE)
		for i in 0 ..< module_count {
			name_buf: [260]u16
			windows.K32GetModuleBaseNameW(handle, modules[i], &name_buf[0], 260)
			name := windows.utf16_to_utf8(&name_buf[0], context.temp_allocator)

			// Check for graphics DLLs
			if strings.contains(name, "d3d9") ||
			   strings.contains(name, "d3d11") ||
			   strings.contains(name, "opengl32") {
				return true
			}
		}
	}
	return false
}
is_main_game_process :: proc(pid: u32) -> bool {
	// Check 1: Must have reasonable memory usage (e.g., > 50MB)
	// memory := get_process_memory_usage(pid)
	// if memory < 50 * 1024 * 1024 do return false

	// Check 2: Should have a visible window
	if !has_game_window(pid) do return false

	// Check 3: Should load graphics DLLs
	// if !has_graphics_dlls(pid) do return false

	return true
}
