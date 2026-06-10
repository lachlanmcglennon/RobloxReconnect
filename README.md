# 🎮 RobloxReconnect

<div align="center">

![Roblox](https://img.shields.io/badge/Roblox-00A2FF?style=for-the-badge&logo=roblox&logoColor=white)
![AutoHotkey](https://img.shields.io/badge/AutoHotkey-334455?style=for-the-badge&logo=autohotkey&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-0078D4?style=for-the-badge&logo=windows&logoColor=white)

**Automated Roblox connection management with a full tabbed GUI**

> 🛡 **V3.2 — smart disconnect detection.** Catches the "Disconnected"
> overlay even when Roblox keeps the process alive: tails the Roblox log
> file in `%LOCALAPPDATA%\Roblox\logs`, detects hung/frozen client
> windows via `IsHungAppWindow`, and closes only the affected PID for
> multi-instance setups. Configurable from the new **Disconnect
> Detection** group on the Monitor tab.
>
> 🚀 **V3.1 baseline:** Built on top of V3.0's tabbed UI, V3.1 ships an
> audit bug-fix pass plus 20 high-value roadmap features:
> profile rotation, JSON import/export, favorites & filter, rebindable hotkeys,
> pause-on-battery, success-rate %, CSV stats export, config backups,
> Roblox status check, self-test, auto-update check and more.
> See [FEATURES.md](./FEATURES.md) for the full 210-feature roadmap.
>
> **Script:** `RobloxReconnectV3.2.Ahk` (V2 / V3.0 / V3.1 kept for legacy reference)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![AutoHotkey v2](https://img.shields.io/badge/AutoHotkey-v2.0-blue.svg)](https://www.autohotkey.com/)
[![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey.svg)](https://www.microsoft.com/en-us/windows)

</div>

---

## ✨ Highlights

### 🔄 Reliable auto-reconnect
- Detects Roblox process exit, error dialogs and disconnect window-titles
- **New in V3.2:** tails Roblox log file for in-game disconnect overlays where the process stays alive (FLog patterns: `Disconnect with reason`, `Disconnected from server`, `ReplicationTimeout`, error codes 17/260/264/268/277/279/522/772, etc.)
- **New in V3.2:** frozen/hung window detection via Win32 `IsHungAppWindow` with a configurable grace period and post-launch suppression to avoid false-killing during shader compile
- **New in V3.2:** per-PID close — only kills the disconnected Roblox instance instead of every `RobloxPlayerBeta.exe`
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

Then double-click `RobloxReconnectV3.2.Ahk` (AHK v2 must be the default `.ahk`
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

1. Launch the script — the GUI opens on the **Monitor** tab.
2. Switch to the **Servers** tab and click **Add** to create a profile
   (VIP link **or** public game ID), give it a name, optionally mark it ★ favorite.
3. Select the profile and click **Set Active**.
4. Switch back to the **Monitor** tab and click **Start Monitoring**, or press `F1`.
5. (Optional, V3.2) Review the **Disconnect Detection** group at the bottom of
   the Monitor tab and tune log-tail / hung-window detection to your preference.

The script will now watch for disconnects and auto-reconnect using your active
profile (or rotate through your profiles if **Rotate profiles** is enabled).

---

## ⌨️ Default hotkeys

| Hotkey            | Action                                  |
|-------------------|------------------------------------------|
| `F1`              | Toggle monitoring on / off               |
| `F2`              | Manual reconnect now                     |
| `F3`              | Minimize Roblox window                   |
| `F4`              | Toggle Anti-AFK                          |
| `Ctrl+Shift+R`    | Emergency reconnect                      |
| `Ctrl+Shift+Q`    | Panic stop (kills timers + Anti-AFK)     |

All six are rebindable from **Settings → Hotkeys → Rebind…**.

---

## 🧭 GUI tour

The GUI has nine tabs in this order:

| Tab          | Contents                                                                       |
|--------------|--------------------------------------------------------------------------------|
| Monitor      | Start / stop, reconnect now, current status, check-interval / cooldown / backoff, **Disconnect Detection (V3.2)** group |
| Servers      | Profile list, add / edit / delete, filter, ★ favorite, import / export, rotate |
| Window       | Minimize-after-join, always-on-top, force-kill, process priority, browser-close after join |
| Anti-AFK     | Enable, mouse vs key method, key, interval, jitter, focus gating, pause-during-reconnect |
| Alerts       | Sound on connect/disconnect, volume, tray balloon, per-event toggles, Discord webhook |
| Schedule     | Scheduled rejoin every N hours, stop-at HH:MM, delayed start, stop-after-N, pause-on-battery |
| Stats        | Lifetime + session counters, success rate, CSV export, reset                  |
| Logs         | Live log view, level filter, search, export, clear, copy                      |
| Settings     | Sleep prevention, window persistence, hotkey rebind, log privacy, diagnostics (self-test, status, update) |

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

### v3.2.4
*Hotfix: silent URI swallowing by zombie bootstrapper.*
- 🐛 When `RobloxPlayerLauncher.exe` or `RobloxCrashHandler.exe` is left
  running from a failed prior launch attempt, firing `roblox://` again
  does nothing — the OS hands the URI to the existing handler which
  silently discards it. Symptom: script repeatedly logs
  "Roblox launched, waiting for load..." followed by "did not stay
  running after launch (60s timeout)" without ever bringing a player
  process up, until the user manually clicks reconnect (which has the
  same effect because the zombie has finally been GC'd by then).
- 🛠 `ReconnectToGame` now kills any stale `RobloxPlayerLauncher.exe` and
  `RobloxCrashHandler.exe` before each launch, but only when
  `RobloxPlayerBeta.exe` itself is NOT running (so we never disturb a
  healthy in-flight bootstrap).
- 🛠 Bumped the post-launch process-appearance window from 30 s to 90 s.
  A cold bootstrap with update check / patch download genuinely takes
  60-90 s; the old 30 s window was guaranteed to false-fail in that
  case and fire a fresh URI on top of the in-flight bootstrapper,
  multiplying the zombie problem.

### v3.2.3
*Critical hotfix: v3.2.2 WaitForGameJoin false-positive timeout.*
- 🐛 **CRITICAL** `WaitForGameJoin` always snapshotted the log file's
  current length before waiting, on the assumption it might be a stale
  rotated log. But Roblox typically writes the `Connection accepted from
  <ip>` marker **2–3 s after starting the session**, while our caller
  doesn't enter `WaitForGameJoin` until the stable-launch check finishes
  (~6–10 s in). Result: the marker was already past our snapshot offset
  → 90 s timeout → false "lobby stuck" → kill working session → endless
  reconnect loop on a perfectly-fine game.
- 🛠 Fix: check the latest log file's creation time. If it was created
  in the last 120 s it's THIS launch's log (Roblox starts a new file per
  session), so scan from offset 0. Only snapshot-and-watch behaviour is
  used when reusing a stale (pre-existing) log file.
- 📝 Logs the chosen strategy at info level
  (`tailing <path> from start (fresh session)` or
  `from offset N (stale log)`) so future false positives are easy to
  diagnose.

### v3.2.2
*Lobby-stuck detection.*
- ✨ **`WaitForGameJoin` post-launch check.** After `ReconnectToGame`
  confirms `RobloxPlayerBeta.exe` is stably running, it now tails the
  latest Roblox log in `%LOCALAPPDATA%\Roblox\logs` for up to 90 s
  looking for `[DFLog::NetworkClient] Connection accepted from <ip>`
  (also accepts `DataModelLoadingPhase::OnAfterLoadingComplete` and
  `joinGamePostStandard finished`). This is the unambiguous marker that
  the client actually joined a game server rather than sitting on the
  Roblox home / main page after a failed deep-link.
- 🐛 On timeout, the lobby instance is closed via `CloseRobloxInstance(0)`
  and the next `MonitorTick` triggers a fresh reconnect with the proper
  retry/backoff flow.
- 🛡 **Fail-open** on missing log directory (Microsoft Store / Bloxstrap
  installs etc.) — logs a Warn and assumes success so we don't kill
  working sessions just because the FLog path differs.
- 🛡 Snapshots the log file length before waiting and only scans **new**
  content, so a stale `Connection accepted` line from a previous session
  in the same rotated log file can't produce a false positive. Mid-wait
  log rotation is handled by re-resolving `GetLatestRobloxLog()`.

### v3.2.1
*Hotfix: phantom-crash loop. Anyone running V3.2.0 should upgrade immediately.*
- 🐛 **CRITICAL** Fixed a false-positive reconnect loop that fired every
  `CheckIntervalSec` (could be ~100 reconnects/minute on a 1-second
  interval). Root cause: `ReconnectToGame` declared "Joined successfully"
  after a blind `Sleep(8000)` without verifying `RobloxPlayerBeta.exe`
  was actually running — but the `roblox://` URI bootstrap can take
  15–30 s. The next `MonitorTick` would then see the process still
  bootstrapping, count a phantom crash, and reconnect again. On a
  browser-launched VIP link this spawned a new browser window per cycle
  (observed: 100 open browser windows after a short outage).
- 🐛 `MonitorTick` now applies the same post-launch grace
  (`HangGraceSec + 60 s`) to **process-exit** detection that V3.2.0 already
  applied to hung-window detection. No more phantom crashes during
  bootstrap.
- 🐛 `ReconnectToGame` now polls `ProcessExist("RobloxPlayerBeta.exe")`
  for 3 consecutive stable checks (2 s apart, up to 60 s total) before
  declaring success. A bootstrap that exits without spawning the player
  is now correctly reported as a failed reconnect.
- ✨ **Heartbeat log** every 5 minutes (`Heartbeat #N | monitoring=… |
  roblox=…`). Lets you tell at a glance whether the script is alive.
- ✨ **OnExit hook** logs *why* AHK shut down (clean exit / Ctrl+C /
  logoff / shutdown / error), so you can tell whether a missed
  reconnect was because the script died vs. detection failed.
- ✨ **System-resume handler** (`WM_POWERBROADCAST`) re-arms `CheckTimer`
  and `LogTailTimer` after the laptop wakes from sleep. AHK timers can be
  stranded in a "set but never firing" state across suspend/resume.
- ✨ **Stuck-state watchdog** force-clears `ReconnectInProgress` if it
  stays true for >5 min (belt-and-braces against exception paths that
  swallowed the cleanup).

**If you're upgrading from V3.2.0 and your stats look wildly inflated
(e.g. hundreds of reconnects when you expected single digits), open the
Stats tab and click **Reset lifetime stats** — the old counts include
the phantom reconnects.**

### v3.2.0
*Tag: `v3.2.0` — first GitHub-tagged release.*
- ✨ **Smart disconnect detection** (Monitor tab → Disconnect Detection group):
  - Roblox log-file tailing for in-game "Disconnected" overlays where the
    process stays alive (configurable poll interval, default 3 s)
  - `IsHungAppWindow`-based frozen-client detection with a configurable
    grace period (default 15 s) and post-launch suppression to prevent
    kill-loops during shader compile / first-place load
  - Per-PID close of only the offending Roblox instance (multi-instance safe)
- 🐛 **CRITICAL:** `LoadConfig` now uses an explicit boolean-key allowlist;
  previously any integer config default of 0 or 1 (e.g. `MaxAttempts`,
  `StopAfterReconnects`, `ActiveProfile`, `DelayedStartSec`, `RejoinMinutes`)
  was misclassified as a boolean on reload and silently clobbered to 0/1
- 🐛 `PullCfgFromGui` no longer throws `TypeError` when a "Number" Edit
  field is cleared; falls back to the previous valid value via `SafeInt`
- 🐛 `ReconnectAttempts` is now reset on a successful reconnect so
  exponential backoff and `MaxAttempts` apply per-incident, not lifetime
- 🐛 Removed false-positive log patterns (`DataModel::close`,
  `NetworkClient::Disconnect`) that fired on legitimate teleports and
  "Leave Game" actions
- 🐛 Re-entrancy guard prevents `LogTailTick`/`MonitorTick` from
  triggering a second reconnect while one is already in progress
- 🔒 Discord webhook URLs, VIP `?privateServerLinkCode=…` tokens, and
  `roblox://` placeId/accessCode parameters are now redacted in `app.log`
- 🛠 **New INI keys** (auto-populated on first run; all also exposed in the
  Monitor tab): `DetectViaLog` (bool, true), `DetectViaHang` (bool, true),
  `HangGraceSec` (int, 15), `LogTailIntervalSec` (int, 3)

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
