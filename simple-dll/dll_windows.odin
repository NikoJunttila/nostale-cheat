package payload
import "core:fmt"
import "core:log"
import "core:os"
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
	logger := setup_logger()
	context.logger = logger
	log.info("starting payload main")
	alert()
	// Create a new console window
	if win.AllocConsole() {
		os.stdin = os.Handle(win.GetStdHandle(win.STD_INPUT_HANDLE))
		os.stdout = os.Handle(win.GetStdHandle(win.STD_OUTPUT_HANDLE))
		os.stderr = os.Handle(win.GetStdHandle(win.STD_ERROR_HANDLE))
	} else {
		fmt.eprintln("error creating console")
		return
	}
	for {
		time.sleep(1000 * time.Millisecond)
	}
}
