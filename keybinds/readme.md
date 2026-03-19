https://github.com/ReimuNotMoe/ydotool

using this to automate keypresses

add to daemon

```
sudo nvim /etc/systemd/system/ydotool.service
```

[Unit]
Description=ydotool daemon

[Service]
ExecStart=/usr/bin/ydotoold
Restart=always

[Install]
WantedBy=multi-user.target

```
systemctl --user enable --now ydotool
```
