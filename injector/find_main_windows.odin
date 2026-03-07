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

is_main_game_process :: proc(pid: u32) -> bool {
	// Check: Should have a visible window
	return has_game_window(pid)
}
