package payload

import "core:fmt"
import os "core:os/old"
import win "core:sys/windows"

setup_console :: proc() {
	if win.AllocConsole() {
		os.stdin = os.Handle(win.GetStdHandle(win.STD_INPUT_HANDLE))
	} else {
		fmt.println("error creating console")
		return
	}
}
