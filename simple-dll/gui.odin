#+build windows
package payload

import "base:runtime"
import "core:fmt"
import win "core:sys/windows"
import mu "vendor:microui"

// Global MicroUI Context for the GUI
gui_ctx: mu.Context
gui_hwnd: win.HWND

gui_log_buf: [1 << 16]byte
gui_log_buf_len: int
gui_log_buf_updated: bool

// ---------------------------------------------------------------------------
// MOB_GRINDING: cached entity / item snapshot
// ---------------------------------------------------------------------------

MobGrindCache :: struct {
	entities: []Entity,
	items:    []Item,
}

mob_grind_cache: MobGrindCache

refresh_mob_grind_cache :: proc() {
	log_info(fmt.tprintf("refreshing %d entities and %d items", len(mob_grind_cache.entities), len(mob_grind_cache.items)))
	for &e in mob_grind_cache.entities {
		delete(e.name)
	}
	delete(mob_grind_cache.entities)
	for &i in mob_grind_cache.items {
		delete(i.name)
	}

	delete(mob_grind_cache.items)
	mob_grind_cache.entities = get_entities()
	mob_grind_cache.items = get_items()
}

write_gui_log :: proc(str: string) {
	if gui_log_buf_len + len(str) + 1 > len(gui_log_buf) {
		gui_log_buf_len = 0
	}
	gui_log_buf_len += copy(gui_log_buf[gui_log_buf_len:], str)
	gui_log_buf_len += copy(gui_log_buf[gui_log_buf_len:], "\n")
	gui_log_buf_updated = true
}

read_gui_log :: proc() -> string {
	return string(gui_log_buf[:gui_log_buf_len])
}

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
		100,
		100,
		800, // w
		900, // h
		nil,
		nil,
		hInstance,
		nil,
	)

	mu.init(&gui_ctx)
	gui_ctx.text_width = gui_text_width
	gui_ctx.text_height = gui_text_height

	win.ShowWindow(gui_hwnd, win.SW_SHOWDEFAULT)
	win.UpdateWindow(gui_hwnd)

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

	if mu.begin_window(&gui_ctx, "Bot Control", {10, 10, 280, 440}, mu.Options{.NO_CLOSE}) {
		// Player info display
		mu.layout_row(&gui_ctx, {-1}, 0)
		name_to_show := bot.username
		if name_to_show == "" {
			name_to_show = bot.playerID
		}
		player_info_str := fmt.tprintf("Player: %s (SP: %d)", name_to_show, bot.playerSP)
		mu.label(&gui_ctx, player_info_str)

		// Current mode display
		mu.layout_row(&gui_ctx, {-1}, 0)
		current_mode_str := fmt.tprintf("Current Mode: %s", mode_names[bot.mode])
		mu.label(&gui_ctx, current_mode_str)

		// Separator
		mu.layout_row(&gui_ctx, {-1}, 8)
		mu.label(
			&gui_ctx,
			"─────────────────────────",
		)

		// Mode selection header
		mu.layout_row(&gui_ctx, {-1}, 0)
		mu.label(&gui_ctx, "Select Mode:")

		// Mode buttons — two per row
		modes := [?]Mode {
			.PAUSED,
			.FISHING,
			.COOKING,
			.DPSCheck,
			.BUFFING,
			.ICE_FLOWER,
			.MOB_GRINDING,
		}

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
		mu.label(
			&gui_ctx,
			"─────────────────────────",
		)
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
				if state.current_round > 0 {
					mu.label(&gui_ctx, fmt.tprintf("Round: %d", state.round_number))
					mu.label(&gui_ctx, fmt.tprintf("DMG: %d", state.current_round))
					mu.label(&gui_ctx, fmt.tprintf("Points: %d", state.activation_points))
					if state.rewards_achieved {
						mu.label(&gui_ctx, "REWARDS: ACHIEVED!")
					} else {
						mu.label(&gui_ctx, "REWARDS: PENDING")
					}
				} else {
					mu.label(&gui_ctx, "STATUS: Waiting for ic / asgobas")
				}
			}
		case .MOB_GRINDING:
			pos := get_player_pos()
			mu.layout_row(&gui_ctx, {-1}, 0)
			mu.label(&gui_ctx, fmt.tprintf("Pos: (%d, %d)", pos.x, pos.y))
			mu.layout_row(&gui_ctx, {-1}, 0)
			mu.label(
				&gui_ctx,
				fmt.tprintf(
					"Enemies: %d   Drops: %d",
					count_alive_entities(mob_grind_cache.entities),
					len(mob_grind_cache.items),
				),
			)
			mu.layout_row(&gui_ctx, {-1}, 0)
			if .SUBMIT in mu.button(&gui_ctx, "Refresh Lists") {
				refresh_mob_grind_cache()
			}
		}

		// Actions
		mu.layout_row(&gui_ctx, {-1}, 8)
		mu.label(
			&gui_ctx,
			"─────────────────────────",
		)
		mu.layout_row(&gui_ctx, {-1}, 0)
		mu.label(&gui_ctx, "Actions:")
		if .SUBMIT in mu.button(&gui_ctx, "Asgobas Timer") {
			asgobas_timer()
		}

		mu.end_window(&gui_ctx)
	}

	// Damage Chart Window (only shown during DPSCheck)
	if bot.mode == .DPSCheck {
		if mu.begin_window(&gui_ctx, "Damage Chart", {10, 460, 280, 400}, mu.Options{.NO_CLOSE}) {
			if state, ok := bot.state.(DPSCheckState); ok {
				mu.layout_row(&gui_ctx, {-1}, -28)
				mu.begin_panel(&gui_ctx, "DMG_List")
				mu.layout_row(&gui_ctx, {-1}, 0)
				for p, i in state.sorted_raid_list {
					mu.label(&gui_ctx, fmt.tprintf("%d. %s : %.1fM", i + 1, p.name, f64(p.dmg) / 1_000_000.0))
				}
				mu.end_panel(&gui_ctx)

				mu.layout_row(&gui_ctx, {-1}, 0)
				if .SUBMIT in mu.button(&gui_ctx, "Reset DMG List") {
					new_state := state
					DPS_reset_raid_list(&new_state)
					DPS_rebuild_sorted_list(&new_state)
					bot.state = new_state
				}
			}
			mu.end_window(&gui_ctx)
		}
	}

	// -----------------------------------------------------------------------
	// MOB_GRINDING window – entity list + item list with click-to-act buttons
	// -----------------------------------------------------------------------
	if bot.mode == .MOB_GRINDING {
		if mu.begin_window(
			&gui_ctx,
			"Mob Grinding - Map Entities",
			{10, 460, 760, 420},
			mu.Options{.NO_CLOSE},
		) {
			pos := get_player_pos()

			// ---- Enemies ----
			mu.layout_row(&gui_ctx, {-1}, 0)
			mu.label(
				&gui_ctx,
				fmt.tprintf(
					"Enemies  (%d alive  /  %d total)",
					count_alive_entities(mob_grind_cache.entities),
					len(mob_grind_cache.entities),
				),
			)

			mu.layout_row(&gui_ctx, {-1}, 175)
			mu.begin_panel(&gui_ctx, "EnemyList")
			for e in mob_grind_cache.entities {
				if !entity_alive(e) do continue
				dist := chebyshev_dist(pos.x, pos.y, e.x, e.y)
				mu.layout_row(&gui_ctx, {-1}, 0)
				btn_lbl := fmt.tprintf("[Attack]  %s  (%d, %d)  dist=%d", e.name, e.x, e.y, dist)
				if .SUBMIT in mu.button(&gui_ctx, btn_lbl) {
					game_attack_monster(e.ptr, 1)
				}
			}
			mu.end_panel(&gui_ctx)

			// ---- Items ----
			mu.layout_row(&gui_ctx, {-1}, 0)
			mu.label(&gui_ctx, fmt.tprintf("Drops  (%d)", len(mob_grind_cache.items)))

			mu.layout_row(&gui_ctx, {-1}, -1)
			mu.begin_panel(&gui_ctx, "ItemList")
			for item in mob_grind_cache.items {
				if item.ptr == 0 do continue
				dist := chebyshev_dist(pos.x, pos.y, item.x, item.y)
				mu.layout_row(&gui_ctx, {-1}, 0)
				btn_lbl := fmt.tprintf(
					"[Loot]  %s  (%d, %d)  dist=%d",
					item.name,
					item.x,
					item.y,
					dist,
				)
				if .SUBMIT in mu.button(&gui_ctx, btn_lbl) {
					game_collect(item.ptr)
				}
			}
			mu.end_panel(&gui_ctx)

			mu.end_window(&gui_ctx)
		}
	}

	opts := mu.Options{.NO_CLOSE}
	if mu.begin_window(&gui_ctx, "Log Window", {300, 10, 480, 440}, opts) {
		mu.layout_row(&gui_ctx, {-1}, -28)
		mu.begin_panel(&gui_ctx, "Log")
		mu.layout_row(&gui_ctx, {-1}, -1)
		mu.text(&gui_ctx, read_gui_log())
		if gui_log_buf_updated {
			panel := mu.get_current_container(&gui_ctx)
			panel.scroll.y = panel.content_size.y
			gui_log_buf_updated = false
		}
		mu.end_panel(&gui_ctx)
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
			win.TextOutW(
				mem_dc,
				variant.pos.x,
				variant.pos.y,
				cast(win.LPCWSTR)raw_data(str),
				i32(len(str)),
			)

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
