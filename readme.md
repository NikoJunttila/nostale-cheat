making a bot for nostale.

new os package has some serious problems with the 32bit windows. quitly crashing everywhere.

## get nice names in GUI

add this kind of users.json to simple-dll dir
with correct ids. easy to get ids from logs or other packet loggers
[
  {
    "username": "ran",
    "id": "3"
  },
  {
    "username": "WK_BUFFER",
    "id": "8"
  },
  {
    "username": "HOLY_BUFFER",
    "id": "8"
  }
]

## linux injection inside proton

my main account folder.
protontricks -c 'wine injector.exe' 4240740151

steam smurf: 550470
when running the steam native version it goes to just steam.
/home/derp/.steam/steam/steamapps/common/NosTale

## Payload logging

The injected DLL now emits diagnostics through `OutputDebugStringA` so you can view everything without touching the game’s console or filesystem.

1. Run [DebugView](https://learn.microsoft.com/sysinternals/downloads/debugview) (start it as Administrator so it captures global output).
2. Enable **Capture Global Win32** from the Capture menu and optionally filter to `[PAYLOAD]` messages.
3. Run `build.bat` and inject the DLL; every heart beat writes `"[PAYLOAD] INFO"` or `"[PAYLOAD] WARN"` lines to DebugView.
4. When DebugView shows the logs, you know the DLL is executing without touching the host process.


## dll payload docs 

currently math/random crashesh the game??? so just call times without random


# linux side

logs
tail -f /home/derp/.steam/steam/steamapps/compatdata/4240740151/pfx/drive_c/Nostale/payload_debug.log
tail -f /home/derp/.steam/steam/steamapps/compatdata/4240740151/pfx/drive_c/Nostale/payload_payload_sent_packets.log

sound is relational to the nostale folder where exe is injected so do this for alert sound.
cp alert.wav /home/derp/.steam/steam/steamapps/compatdata/4240740151/pfx/drive_c/Nostale/

## ai info

This is a project written with odin for injecting nostale video game that is 32bit with a .dll file.
This targets windows environment only but usually is ran in linux through proton.


