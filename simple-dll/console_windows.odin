package payload

import "core:fmt"
import os "core:os/old"
import win "core:sys/windows"

// foreign import kernel32 "system:Kernel32.lib"
//
// @(default_calling_convention = "system")
// foreign kernel32 {
// 	// SetConsoleTitle :: proc(lpConsoleTitle: win.LPCTSTR) -> win.BOOL ---
// }

setup_console :: proc() {
	if win.AllocConsole() == false {
		fmt.println("error creating console")
		return
	}
	setdin := win.GetStdHandle(win.STD_INPUT_HANDLE)
	stout := win.GetStdHandle(win.STD_OUTPUT_HANDLE)
	sterr := win.GetStdHandle(win.STD_ERROR_HANDLE)
	os.stdin = os.Handle(setdin)
	os.stdout = os.Handle(stout)
	os.stderr = os.Handle(sterr)
	// SetConsoleTitle("fish bot")
}
