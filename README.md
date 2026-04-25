# 🎮 RobloxReconnect

<div align="center">

![Roblox](https://img.shields.io/badge/Roblox-00A2FF?style=for-the-badge&logo=roblox&logoColor=white)
![AutoHotkey](https://img.shields.io/badge/AutoHotkey-334455?style=for-the-badge&logo=autohotkey&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-0078D4?style=for-the-badge&logo=windows&logoColor=white)

**Automated Roblox connection management with a full tabbed GUI**

> 🚀 **V3.1 is here!** Built on top of V3.0's tabbed UI, V3.1 ships an audit
> bug-fix pass plus 20 high-value roadmap features:
> profile rotation, JSON import/export, favorites & filter, rebindable hotkeys,
> pause-on-battery, success-rate %, CSV stats export, config backups,
> Roblox status check, self-test, auto-update check and more.
> See [FEATURES.md](./FEATURES.md) for the full 200-feature roadmap.
>
> **Script:** `RobloxReconnectV3.1.Ahk` (V2 / V3.0 kept for legacy reference)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![AutoHotkey v2](https://img.shields.io/badge/AutoHotkey-v2.0-blue.svg)](https://www.autohotkey.com/)
[![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey.svg)](https://www.microsoft.com/en-us/windows)

</div>

---

## ✨ Highlights

### 🔄 Reliable auto-reconnect
- Detects Roblox process exit, error dialogs and disconnect window-titles
- Configurable check interval, max attempts cap, cooldown, exponential backoff and jitter
- Pre-checks internet connectivity (skips when offline)
- Optional Roblox status API ping before reconnecting

### 🗂️ Multi-profile server manager
- VIP private-link or public game-ID profiles, per-profile notes
- Favorites (★), live filter / search, JSON import / export
- Profile rotation: cycle to next profile on each reconnect
- VIP link masking in UI + redaction in logs (privacy)

### ⏰ Scheduling & limits
- Scheduled rejoin every N hours / M minutes
- "Stop at" wall-clock time, daily quiet-hours window
- Lifetime stop-after-N reconnects
- Pause-on-battery (laptop power-aware via `GetSystemPowerStatus`)

### 💤 Anti-AFK
- Configurable key, interval and jitter
- Optional pause during reconnect window so it can't fight the launcher

### 🔔 Alerts
- Optional sound on disconnect / reconnect with master volume slider
- Tray balloon notifications, Discord webhook ping
- Per-event toggles

### 📊 Stats & logs
- Lifetime reconnect / crash counters, uptime tracking
- Successful vs failed reconnect breakdown + success-rate %
- CSV export of stats
- In-app log viewer with filter, search, autoscroll and export

### 🛠️ Tooling
- Tray icon with right-click menu, hide-to-tray on close
- Roblox-process priority management
- Self-test diagnostic, GitHub release update check
- Config backups (last 20) on every save
- Window position / size persistence
- Rebindable hotkeys

---

## 📋 Requirements

- **Windows 10 / 11** (8 / 7 should work but is untested)
- **AutoHotkey v2.0+** ([download](https://www.autohotkey.com/))
- **Roblox** installed (works with the Microsoft Store and standalone clients)

---

## 🚀 Installation

```powershell
git clone https://github.com/lachlanmcglennon/RobloxReconnect.git
cd RobloxReconnect
```

Then double-click `RobloxReconnectV3.1.Ahk` (AHK v2 must be the default `.ahk`
handler) or right-click → **Run with AutoHotkey**.

On first launch the script creates a `RobloxReconnect-Data\` folder next to the
script and writes config / profiles / stats / logs there.

```
RobloxReconnect-Data\
├── config.ini             # main settings
├── profiles.ini           # saved server profiles
├── stats.ini              # lifetime counters
├── app.log                # rotating activity log
└── config-backups\        # auto-saved snapshots (last 20)
```

---

## 🎯 Quick start

1. Launch the script — the GUI opens on the **Servers** tab.
2. Click **Add** to create a profile (VIP link **or** public game ID), give it a
   name, optionally mark it ★ favorite.
3. Select the profile and click **Set Active**.
4. Switch to the **General** tab and click **Start Monitoring**, or press `F1`.

The script will now watch for disconnects and auto-reconnect using your active
profile (or rotate through your profiles if **Rotate profiles** is enabled).

---

## ⌨️ Default hotkeys

| Hotkey            | Action                                  |
|-------------------|------------------------------------------|
| `F1`              | Toggle monitoring on / off               |
| `F2`              | Manual reconnect now                     |
| `F3`              | Show / hide the GUI                      |
| `F4`              | Toggle Anti-AFK                          |
| `Ctrl+Shift+R`    | Emergency reconnect                      |
| `Ctrl+Shift+Q`    | Panic stop (kills timers + Anti-AFK)     |

All six are rebindable from **Settings → Hotkeys → Rebind…**.

---

## 🧭 GUI tour

| Tab          | Contents                                                                       |
|--------------|--------------------------------------------------------------------------------|
| General      | Start / stop, reconnect now, current status, last reconnect time              |
| Servers      | Profile list, add / edit / delete, filter, ★ favorite, import / export, rotate |
| Anti-AFK     | Enable, key, interval, jitter, pause-during-reconnect                          |
| Schedule     | Scheduled rejoin, stop-at time, quiet hours, stop-after-N, pause-on-battery   |
| Alerts       | Sound on connect/disconnect, volume, tray balloon, Discord webhook             |
| Stats        | Lifetime + session counters, success rate, CSV export                          |
| Logs         | Live log view, level filter, search, export, clear                             |
| Settings     | Window persistence, hotkey rebind, diagnostics (self-test, status, update)    |

---

## 🐛 Troubleshooting

- **Script won't start** — make sure AutoHotkey **v2** is installed (v1 will not work).
- **Reconnect launches the website instead of the app** — Windows must have a
  Roblox protocol handler registered. Re-install Roblox or run the Microsoft
  Store version once.
- **Hotkeys do nothing** — another app may have claimed them; rebind under
  **Settings → Hotkeys**.
- **Self-test fails on Roblox install path** — open `Settings → Diagnostics` and
  inspect the message; the script searches the standard `%LocalAppData%\Roblox\Versions` location.

Logs land in `RobloxReconnect-Data\app.log` and the **Logs** tab.

---

## 🤝 Contributing

PRs welcome — please:

1. Fork → feature branch → PR
2. Stick to AutoHotkey v2 syntax (`#Requires AutoHotkey v2.0`)
3. Update [`FEATURES.md`](./FEATURES.md) when shipping a roadmap item
4. Test on a fresh `RobloxReconnect-Data\` folder before submitting

---

## 📝 Changelog

### v3.1.0
- 🐛 Fixed `ProcessSetPriority` mapping (now uses letter codes)
- 🐛 `AppendLogToView` now trims old lines instead of wiping the view
- 🐛 `LoadConfig` boolean detection (was masked by `Integer` check)
- ✨ Profile rotation, favorites, filter, JSON import/export
- ✨ VIP link masking + log redaction
- ✨ Rebindable hotkeys, window-position persistence
- ✨ Pause Anti-AFK during reconnect, sound volume slider
- ✨ Stop-after-N, pause-on-battery
- ✨ Roblox status check, self-test, auto-update check
- ✨ CSV stats export, config-backup on save
- ✨ Status-bar control hints

### v3.0.0
- 🎉 Full tabbed-UI rebuild with multi-profile manager, anti-AFK, scheduling,
      Discord webhooks, tray icon and 70+ features.

### v1.0.0
- ✨ Initial release

---

## 📜 License

MIT — see [LICENSE](LICENSE).

---

## ⚠️ Disclaimer

This tool is for educational and convenience purposes only. Use at your own
risk and ensure compliance with Roblox's Terms of Service. The developers are
not responsible for any account actions taken by Roblox.

---

<div align="center">

**Made with ❤️ for the Roblox community**

[Report Bug](https://github.com/lachlanmcglennon/RobloxReconnect/issues) • [Request Feature](https://github.com/lachlanmcglennon/RobloxReconnect/issues)

</div>
