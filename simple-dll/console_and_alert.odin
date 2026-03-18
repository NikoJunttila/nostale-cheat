#+build windows
package payload

import "core:fmt"
import win "core:sys/windows"

foreign import kernel32 "system:Kernel32.lib"

@(default_calling_convention = "system")
foreign kernel32 {
	@(link_name = "SetConsoleTitleA")
	SetConsoleTitle :: proc(lpConsoleTitle: win.LPCSTR) -> win.BOOL ---
}

// does not work. just here so I can cleanly quit the program
setup_console :: proc() {
	when ODIN_DEBUG {
		if win.AllocConsole() == false {
			fmt.println("error creating console")
			return
		}
		SetConsoleTitle("fish bot\x00") // this creates the console and makes correct title but no stouts get logged
		fmt.println("made new console")
	}
}

alert :: proc() {
	log_warn("alert!!!")
	play_alert_sound()
	// Create a new thread so the MessageBox doesn't block the main generic payload execution.
	winstring := win.utf8_to_wstring("admin alert")
	winTitle := win.utf8_to_wstring("admin alert")
	win.MessageBoxW(nil, winstring, winTitle, win.MB_OK | win.MB_TOPMOST | win.MB_ICONWARNING)
}

play_alert_sound :: proc() {
	// only .wav files
	// this is loaded from inside the the program .dll gets injected to and using relative will fail unless its inside the folder actually running game
	// relational and place the alert in nostale folder
	ok := win.PlaySoundW(`alert.wav`, nil, win.SND_FILENAME | win.SND_ASYNC)
	if !ok {
		log_warn("failed to play alert sound")
	} else {
		log_info("playing sound")
	}
}
