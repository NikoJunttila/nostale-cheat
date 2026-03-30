package main

import "core:sys/windows"
import "base:runtime"
import mu "vendor:microui"
import "core:fmt"

// Global MicroUI Context
mu_ctx: mu.Context

// DLL Entry/Init
@(init)
setup :: proc "contextless" () {
	windows.CreateThread(nil, 0, main_thread, nil, 0, nil)
}

main_thread :: proc "stdcall" (param: windows.LPVOID) -> windows.DWORD {
	context = runtime.default_context()
	run_gui()
	return 0
}

mu_text_width :: proc(font: mu.Font, str: string) -> i32 {
	return i32(len(str)) * 8
}

mu_text_height :: proc(font: mu.Font) -> i32 {
	return 16
}

run_gui :: proc() {
	hInstance := cast(windows.HINSTANCE)windows.GetModuleHandleW(nil)
	
	// IDC_ARROW is 32512.
	hCursor := windows.LoadCursorW(nil, cast(windows.LPCWSTR)windows.MAKEINTRESOURCEW(32512))

	className := windows.L("OdinMicroUIClass")
	wc := windows.WNDCLASSEXW {
		cbSize = size_of(windows.WNDCLASSEXW),
		style = windows.CS_HREDRAW | windows.CS_VREDRAW,
		lpfnWndProc = window_proc,
		hInstance = hInstance,
		hCursor = hCursor,
		lpszClassName = cast(windows.LPCWSTR)className,
	}
	windows.RegisterClassExW(&wc)

	hwnd := windows.CreateWindowExW(
		0, cast(windows.LPCWSTR)className, cast(windows.LPCWSTR)windows.L("Odin Bot - MicroUI GDI Verification"),
		windows.WS_OVERLAPPEDWINDOW,
		100, 100, 500, 400,
		nil, nil, hInstance, nil,
	)

	mu.init(&mu_ctx)
	mu_ctx.text_width = mu_text_width
	mu_ctx.text_height = mu_text_height

	windows.ShowWindow(hwnd, windows.SW_SHOWDEFAULT)
	windows.UpdateWindow(hwnd)

	msg: windows.MSG
	for windows.GetMessageW(&msg, nil, 0, 0) > 0 {
		windows.TranslateMessage(&msg)
		windows.DispatchMessageW(&msg)
		
		// Update and Redraw
		update_ui()
		windows.InvalidateRect(hwnd, nil, windows.FALSE)
	}
}

update_ui :: proc() {
	mu.begin(&mu_ctx)
	if mu.begin_window(&mu_ctx, "Verification", {40, 40, 300, 200}) {
		mu.layout_row(&mu_ctx, {-1}, 0)
		mu.label(&mu_ctx, "Odin + MicroUI (GDI) Working!")
		mu.label(&mu_ctx, "Compatible with VMs!")
		if .SUBMIT in mu.button(&mu_ctx, "Click Me") {
			fmt.println("Button Clicked!")
		}
		mu.end_window(&mu_ctx)
	}
	mu.end(&mu_ctx)
}

// GDI Renderer for MicroUI
render_mu :: proc(hdc: windows.HDC, width, height: i32) {
	// 1. Create Double Buffer
	mem_dc := windows.CreateCompatibleDC(hdc)
	mem_bm := windows.CreateCompatibleBitmap(hdc, width, height)
	old_bm := windows.SelectObject(mem_dc, windows.HGDIOBJ(mem_bm))

	// 2. Clear Background
	bg_rect := windows.RECT{0, 0, width, height}
	bg_brush := windows.CreateSolidBrush(windows.RGB(30, 30, 30))
	windows.FillRect(mem_dc, &bg_rect, bg_brush)
	windows.DeleteObject(windows.HGDIOBJ(bg_brush))

	// 3. Process Commands
	cmd: ^mu.Command
	for mu.next_command(&mu_ctx, &cmd) {
		switch variant in cmd.variant {
		case ^mu.Command_Rect:
			rect := windows.RECT{variant.rect.x, variant.rect.y, variant.rect.x + variant.rect.w, variant.rect.y + variant.rect.h}
			brush := windows.CreateSolidBrush(windows.RGB(int(variant.color.r), int(variant.color.g), int(variant.color.b)))
			windows.FillRect(mem_dc, &rect, brush)
			windows.DeleteObject(windows.HGDIOBJ(brush))
		
		case ^mu.Command_Text:
			windows.SetTextColor(mem_dc, windows.RGB(int(variant.color.r), int(variant.color.g), int(variant.color.b)))
			windows.SetBkMode(mem_dc, .TRANSPARENT)
			str := windows.utf8_to_utf16(variant.str)
			windows.TextOutW(mem_dc, variant.pos.x, variant.pos.y, cast(windows.LPCWSTR)raw_data(str), i32(len(str)))
		
		case ^mu.Command_Icon:
			rect := windows.RECT{variant.rect.x, variant.rect.y, variant.rect.x + variant.rect.w, variant.rect.y + variant.rect.h}
			brush := windows.CreateSolidBrush(windows.RGB(int(variant.color.r), int(variant.color.g), int(variant.color.b)))
			windows.FrameRect(mem_dc, &rect, brush)
			windows.DeleteObject(windows.HGDIOBJ(brush))
			
		case ^mu.Command_Clip:
			// Skipping clipping for simplicity in PoC
			
		case ^mu.Command_Jump: // Skip
		}
	}

	// 4. BitBlt to Screen
	windows.BitBlt(hdc, 0, 0, width, height, mem_dc, 0, 0, windows.SRCCOPY)

	// 5. Cleanup
	windows.SelectObject(mem_dc, old_bm)
	windows.DeleteObject(windows.HGDIOBJ(mem_bm))
	windows.DeleteDC(mem_dc)
}

window_proc :: proc "stdcall" (hwnd: windows.HWND, msg: windows.UINT, wparam: windows.WPARAM, lparam: windows.LPARAM) -> windows.LRESULT {
	context = runtime.default_context()
	
	switch msg {
	case windows.WM_MOUSEMOVE:
		mu.input_mouse_move(&mu_ctx, i32(windows.LOWORD(cast(windows.DWORD)lparam)), i32(windows.HIWORD(cast(windows.DWORD)lparam)))
	case windows.WM_LBUTTONDOWN:
		mu.input_mouse_down(&mu_ctx, i32(windows.LOWORD(cast(windows.DWORD)lparam)), i32(windows.HIWORD(cast(windows.DWORD)lparam)), .LEFT)
	case windows.WM_LBUTTONUP:
		mu.input_mouse_up(&mu_ctx, i32(windows.LOWORD(cast(windows.DWORD)lparam)), i32(windows.HIWORD(cast(windows.DWORD)lparam)), .LEFT)
	case windows.WM_RBUTTONDOWN:
		mu.input_mouse_down(&mu_ctx, i32(windows.LOWORD(cast(windows.DWORD)lparam)), i32(windows.HIWORD(cast(windows.DWORD)lparam)), .RIGHT)
	case windows.WM_RBUTTONUP:
		mu.input_mouse_up(&mu_ctx, i32(windows.LOWORD(cast(windows.DWORD)lparam)), i32(windows.HIWORD(cast(windows.DWORD)lparam)), .RIGHT)
	
	case windows.WM_PAINT:
		ps: windows.PAINTSTRUCT
		hdc := windows.BeginPaint(hwnd, &ps)
		rect: windows.RECT
		windows.GetClientRect(hwnd, &rect)
		render_mu(hdc, rect.right, rect.bottom)
		windows.EndPaint(hwnd, &ps)
		return 0

	case windows.WM_DESTROY:
		windows.PostQuitMessage(0)
		return 0
	}
	return windows.DefWindowProcW(hwnd, msg, wparam, lparam)
}
