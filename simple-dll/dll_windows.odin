package payload
import "core:fmt"
import os "core:os/old"
import win "core:sys/windows"
import "core:time"

LPTHREAD_START_ROUTINE :: #type proc "stdcall" (parameter: rawptr) -> u32

alert :: proc() {
	winstring := win.utf8_to_wstring("alert called")
	winTitle := win.utf8_to_wstring("You've been hacked")
	win.MessageBoxW(nil, winstring, winTitle, win.MB_OK)
}

console_handle: win.HANDLE

actual_main :: proc() {
	alert()
	// Create a new console window
	// if win.AllocConsole() {
	// 	os.stdin = os.Handle(win.GetStdHandle(win.STD_INPUT_HANDLE))
	// 	os.stdout = os.Handle(win.GetStdHandle(win.STD_OUTPUT_HANDLE))
	// 	os.stderr = os.Handle(win.GetStdHandle(win.STD_ERROR_HANDLE))
	// } else {
	// 	fmt.eprintln("error creating console")
	// 	return
	// }
	for {
		fmt.println("loop inside payload")
		time.sleep(1000 * time.Millisecond)
	}
}
