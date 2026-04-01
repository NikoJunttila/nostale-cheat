#+build windows
package payload

import win "core:sys/windows"
import "base:runtime"
import mu "vendor:microui"
import "core:fmt"

// Global MicroUI Context for the GUI
gui_ctx: mu.Context
gui_hwnd: win.HWND

// Mode names for display
mode_names := [Mode]string {
	.PAUSED       = "PAUSED",
	.FISHING      = "FISHING",
	.COOKING      = "COOKING",
	.DPSCheck     = "DPS Check",
	.BUFFING      = "BUFFING",
	.ICE_FLOWER   = "ICE FLOWER",
	.MOB_GRINDING = "MOB GRINDING",
}

gui_text_width :: proc(font: mu.Font, str: string) -> i32 {
	return i32(len(str)) * 7
}

gui_text_height :: proc(font: mu.Font) -> i32 {
	return 16
}

start_gui :: proc() {
	hInstance := cast(win.HINSTANCE)win.GetModuleHandleW(nil)
	hCursor := win.LoadCursorW(nil, cast(win.LPCWSTR)win.MAKEINTRESOURCEW(32512))

	className := win.L("PayloadGUIClass")
	wc := win.WNDCLASSEXW {
		cbSize        = size_of(win.WNDCLASSEXW),
		style         = win.CS_HREDRAW | win.CS_VREDRAW,
		lpfnWndProc   = gui_window_proc,
		hInstance     = hInstance,
		hCursor       = hCursor,
		lpszClassName = cast(win.LPCWSTR)className,
	}
	win.RegisterClassExW(&wc)

	gui_hwnd = win.CreateWindowExW(
		win.WS_EX_TOPMOST,
		cast(win.LPCWSTR)className,
		cast(win.LPCWSTR)win.L("Bot Control"),
		win.WS_OVERLAPPEDWINDOW,
		100, 100, 320, 500,
		nil, nil, hInstance, nil,
	)

	mu.init(&gui_ctx)
	gui_ctx.text_width = gui_text_width
	gui_ctx.text_height = gui_text_height

	win.ShowWindow(gui_hwnd, win.SW_SHOWDEFAULT)
	win.UpdateWindow(gui_hwnd)

	log_info("GUI started")

	msg: win.MSG
	for win.GetMessageW(&msg, nil, 0, 0) > 0 {
		win.TranslateMessage(&msg)
		win.DispatchMessageW(&msg)

		update_gui()
		win.InvalidateRect(gui_hwnd, nil, win.FALSE)
		free_all(context.temp_allocator)
	}
}

update_gui :: proc() {
	mu.begin(&gui_ctx)

	if mu.begin_window(&gui_ctx, "Bot Control", {10, 10, 280, 440}) {
		// Current mode display
		mu.layout_row(&gui_ctx, {-1}, 0)
		current_mode_str := fmt.tprintf("Current Mode: %s", mode_names[bot.mode])
		mu.label(&gui_ctx, current_mode_str)

		// Separator
		mu.layout_row(&gui_ctx, {-1}, 8)
		mu.label(&gui_ctx, "─────────────────────────")

		// Mode selection header
		mu.layout_row(&gui_ctx, {-1}, 0)
		mu.label(&gui_ctx, "Select Mode:")

		// Mode buttons — two per row
		modes := [?]Mode{.PAUSED, .FISHING, .COOKING, .DPSCheck, .BUFFING, .ICE_FLOWER, .MOB_GRINDING}

		for m in modes {
			mu.layout_row(&gui_ctx, {-1}, 0)
			label := mode_names[m]

			// Highlight active mode
			if bot.mode == m {
				active_label := fmt.tprintf("> %s <", label)
				mu.label(&gui_ctx, active_label)
			} else {
				if .SUBMIT in mu.button(&gui_ctx, label) {
					set_bot_mode(m)
				}
			}
		}

		mu.layout_row(&gui_ctx, {-1}, 8)
		mu.label(&gui_ctx, "─────────────────────────")
		mu.layout_row(&gui_ctx, {-1}, 0)
		mu.label(&gui_ctx, "Mode Data:")

		#partial switch bot.mode {
		case .FISHING:
			info := fmt.tprintf("Fish Caught: %d", fish_caught)
			mu.label(&gui_ctx, info)
			if outOfBaits {
				mu.label(&gui_ctx, "STATUS: OUT OF BAITS")
			} else {
				mu.label(&gui_ctx, "STATUS: Active")
			}
		case .COOKING:
			if currently_cooking != "" {
				mu.label(&gui_ctx, fmt.tprintf("Item: %s", currently_cooking))
				mu.label(&gui_ctx, fmt.tprintf("Skill: %s", bot_cooking_skill))
			} else {
				mu.label(&gui_ctx, "STATUS: Waiting to cook...")
			}
		case .DPSCheck:
			if state, ok := bot.state.(DPSCheckState); ok {
				mu.label(&gui_ctx, fmt.tprintf("Type: %v", state.mode))
				if state.mode == .IC {
					mu.label(&gui_ctx, fmt.tprintf("Round: %d", state.round_number))
					mu.label(&gui_ctx, fmt.tprintf("DMG: %d", state.current_round))
					mu.label(&gui_ctx, fmt.tprintf("Points: %d", state.activation_points))
					if state.rewards_achieved {
						mu.label(&gui_ctx, "REWARDS: ACHIEVED!")
					} else {
						mu.label(&gui_ctx, "REWARDS: PENDING")
					}
				} else if state.mode == .RAID {
					mu.label(&gui_ctx, "RAID data active")
				}
			}
		}

		mu.end_window(&gui_ctx)
	}

	mu.end(&gui_ctx)
}

// Set bot mode from the GUI (thread-safe enough for our use case)
set_bot_mode :: proc(new_mode: Mode) {
	if bot.mode == new_mode do return
	reset_skill_que()
	bot.mode = new_mode
	update_state()
	update_bot_sp_level()
	log_info(fmt.tprintf("[GUI] Mode changed to: %s", mode_names[new_mode]))
}

// GDI Double-Buffered Renderer for MicroUI
gui_render :: proc(hdc: win.HDC, width, height: i32) {
	mem_dc := win.CreateCompatibleDC(hdc)
	mem_bm := win.CreateCompatibleBitmap(hdc, width, height)
	old_bm := win.SelectObject(mem_dc, win.HGDIOBJ(mem_bm))

	// Clear background — dark theme
	bg_rect := win.RECT{0, 0, width, height}
	bg_brush := win.CreateSolidBrush(win.RGB(30, 30, 30))
	win.FillRect(mem_dc, &bg_rect, bg_brush)
	win.DeleteObject(win.HGDIOBJ(bg_brush))

	// Process MicroUI draw commands
	cmd: ^mu.Command
	for mu.next_command(&gui_ctx, &cmd) {
		switch variant in cmd.variant {
		case ^mu.Command_Rect:
			rect := win.RECT {
				variant.rect.x,
				variant.rect.y,
				variant.rect.x + variant.rect.w,
				variant.rect.y + variant.rect.h,
			}
			brush := win.CreateSolidBrush(
				win.RGB(int(variant.color.r), int(variant.color.g), int(variant.color.b)),
			)
			win.FillRect(mem_dc, &rect, brush)
			win.DeleteObject(win.HGDIOBJ(brush))

		case ^mu.Command_Text:
			win.SetTextColor(
				mem_dc,
				win.RGB(int(variant.color.r), int(variant.color.g), int(variant.color.b)),
			)
			win.SetBkMode(mem_dc, .TRANSPARENT)
			str := win.utf8_to_utf16(variant.str)
			win.TextOutW(mem_dc, variant.pos.x, variant.pos.y, cast(win.LPCWSTR)raw_data(str), i32(len(str)))

		case ^mu.Command_Icon:
			rect := win.RECT {
				variant.rect.x,
				variant.rect.y,
				variant.rect.x + variant.rect.w,
				variant.rect.y + variant.rect.h,
			}
			brush := win.CreateSolidBrush(
				win.RGB(int(variant.color.r), int(variant.color.g), int(variant.color.b)),
			)
			win.FrameRect(mem_dc, &rect, brush)
			win.DeleteObject(win.HGDIOBJ(brush))

		case ^mu.Command_Clip:
			// Skip clipping for now

		case ^mu.Command_Jump:
			// Skip
		}
	}

	// Blit to screen
	win.BitBlt(hdc, 0, 0, width, height, mem_dc, 0, 0, win.SRCCOPY)

	// Cleanup
	win.SelectObject(mem_dc, old_bm)
	win.DeleteObject(win.HGDIOBJ(mem_bm))
	win.DeleteDC(mem_dc)
}

gui_window_proc :: proc "stdcall" (
	hwnd: win.HWND,
	msg: win.UINT,
	wparam: win.WPARAM,
	lparam: win.LPARAM,
) -> win.LRESULT {
	context = runtime.default_context()

	switch msg {
	case win.WM_MOUSEMOVE:
		mu.input_mouse_move(
			&gui_ctx,
			i32(win.LOWORD(cast(win.DWORD)lparam)),
			i32(win.HIWORD(cast(win.DWORD)lparam)),
		)
	case win.WM_LBUTTONDOWN:
		mu.input_mouse_down(
			&gui_ctx,
			i32(win.LOWORD(cast(win.DWORD)lparam)),
			i32(win.HIWORD(cast(win.DWORD)lparam)),
			.LEFT,
		)
	case win.WM_LBUTTONUP:
		mu.input_mouse_up(
			&gui_ctx,
			i32(win.LOWORD(cast(win.DWORD)lparam)),
			i32(win.HIWORD(cast(win.DWORD)lparam)),
			.LEFT,
		)
	case win.WM_RBUTTONDOWN:
		mu.input_mouse_down(
			&gui_ctx,
			i32(win.LOWORD(cast(win.DWORD)lparam)),
			i32(win.HIWORD(cast(win.DWORD)lparam)),
			.RIGHT,
		)
	case win.WM_RBUTTONUP:
		mu.input_mouse_up(
			&gui_ctx,
			i32(win.LOWORD(cast(win.DWORD)lparam)),
			i32(win.HIWORD(cast(win.DWORD)lparam)),
			.RIGHT,
		)
	case win.WM_MOUSEWHEEL:
		mu.input_scroll(&gui_ctx, 0, i32(cast(i16)win.HIWORD(cast(win.DWORD)wparam)) / -30)

	case win.WM_PAINT:
		ps: win.PAINTSTRUCT
		hdc := win.BeginPaint(hwnd, &ps)
		rect: win.RECT
		win.GetClientRect(hwnd, &rect)
		gui_render(hdc, rect.right, rect.bottom)
		win.EndPaint(hwnd, &ps)
		return 0

	case win.WM_DESTROY:
		win.PostQuitMessage(0)
		return 0
	}
	return win.DefWindowProcW(hwnd, msg, wparam, lparam)
}
