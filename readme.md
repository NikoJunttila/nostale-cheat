making a bot for nostale.

new os package has some serious problems with the 32bit windows. quitly crashing everywhere.

## linux injection inside proton

protontricks -c 'wine injector.exe' 4240740151

## Payload logging

The injected DLL now emits diagnostics through `OutputDebugStringA` so you can view everything without touching the game’s console or filesystem.

1. Run [DebugView](https://learn.microsoft.com/sysinternals/downloads/debugview) (start it as Administrator so it captures global output).
2. Enable **Capture Global Win32** from the Capture menu and optionally filter to `[PAYLOAD]` messages.
3. Run `build.bat` and inject the DLL; every heart beat writes `"[PAYLOAD] INFO"` or `"[PAYLOAD] WARN"` lines to DebugView.
4. When DebugView shows the logs, you know the DLL is executing without touching the host process.


## current progress

packetlogger with send and recv client side packets
