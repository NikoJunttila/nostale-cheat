#+build windows
package payload

import "core:fmt"
import os "core:os/old"
import win "core:sys/windows"

foreign import kernel32 "system:Kernel32.lib"

@(default_calling_convention = "system")
foreign kernel32 {
	@(link_name = "SetConsoleTitleA")
	SetConsoleTitle :: proc(lpConsoleTitle: win.LPCSTR) -> win.BOOL ---
}

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
	SetConsoleTitle("fish bot\x00") // this creates the console and makes correct title but no stouts get logged
	fmt.println("made new console")
}

alert :: proc() {
	log_warn("alert!!!")
	// this call blocks the thread? other nicer ways to pop up a alert notice?
	// winstring := win.utf8_to_wstring("admin alert")
	// winTitle := win.utf8_to_wstring("admin alert")
	// win.MessageBoxW(nil, winstring, winTitle, win.MB_OK)
	play_alert_sound()
}

play_alert_sound :: proc() {
	// only .wav files
	// this is loaded from inside the the program .dll gets injected to and using relative will fail unless its inside the folder actually running game?
	ok := win.PlaySoundW(
		`C:\Users\bill\Desktop\Shared\nostale-cheats/alert.wav`,
		nil,
		win.SND_FILENAME | win.SND_ASYNC,
	)
	if !ok {
		log_warn("failed to play alert sound")
	} else {
		log_info("playing sound")
	}
}
