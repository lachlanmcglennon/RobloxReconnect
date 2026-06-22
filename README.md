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

### v3.2.11
*Multi-method launch ladder so reconnect doesn't give up at the first
silent dispatch failure - tries 3-4 alternative ways to spawn Roblox
before halting.*
- 🆙 **Launch-method ladder.** When the default `Run(target)` path
  fails to spawn `RobloxPlayerBeta.exe` within 60 s, the script now
  falls through to:
  1. `default-shell` — current `Run(target)` (unchanged)
  2. `fresh-browser` — kill all `msedge/chrome/firefox/brave/opera`
     processes first, then re-fire the URL into a clean browser
     (the most common rescue for the 23 Jun cascade — tab pileup
     was the proximate cause)
  3. `url-shortcut-file` — write a `.url` shortcut to `%TEMP%` and
     `ShellExecute` it (uses the exact same code path as a user
     double-clicking a desktop shortcut, bypassing whatever browser
     state was wedged)
  4. `alt-browser:<name>` — if a *non-default* browser is installed
     (Edge/Chrome/Firefox/Brave detected via registry + path scan),
     launch the URL through that one directly
- 🆙 **Circuit-breaker softened.** Now requires 4 *full-ladder*
  failures (~16 min of trying) before auto-stopping, instead of 2
  single-method failures (~3 min). The ladder itself is the primary
  defence; the cap is just for truly unrecoverable cases.
- ✅ Better logging: every method announces itself with
  `Launch method N/M: 'fresh-browser' - kill all browser processes...`
  and on success logs `RobloxPlayerBeta.exe spawned (PID X) after Ys
  on method 'fresh-browser'` so you can see which method actually
  worked.
- ✅ Direct-URI launches (`roblox-player:` / `roblox://`) skip the
  browser-tricks methods and only try `default-shell` +
  `url-shortcut-file`.

### v3.2.10
*Fix the false-positive "Roblox launched" log that allowed a 6-hour
browser-tab cascade overnight, plus add launch-dispatch circuit-breaker
and verbose launch logging.*
- 🐛 **23 June, 03:04 → 09:07 (6 hours) lost.** Roblox disconnected at
  03:03; V3.2.7+V3.2.9 detection correctly fired Reconnect #1, but the
  90s launch-wait trusted `newPid` (returned by `Run("https://...")` =
  the **browser's** PID, not Roblox's). `ProcessExist(browserPid)` was
  instantly true → logged `"Roblox launched, waiting for load..."` →
  stability check then failed because Roblox.exe never actually spawned.
  Only 1 of the 71 retry attempts created a Player session log (proof
  Roblox really started); the other 70 just piled up browser tabs while
  `roblox.com`'s protocol-handoff silently dropped each request.
- ✅ Wait loop now ALWAYS requires a new `RobloxPlayerBeta.exe` PID
  (different from any pre-existing sibling) before logging
  `"Roblox launched"`. Eliminates the false-positive entirely.
- ✅ Launch-dispatch circuit-breaker: after 2 consecutive "Roblox never
  spawned within 90s" failures, monitoring auto-STOPS with a tray
  notification. Last night's 71-attempt cascade would have been 2.
- ✅ Verbose launch logging: target kind (`direct-URI` vs
  `https-via-browser`), `Run()` returned PID *and* its process name
  (e.g. `msedge.exe`), 10s progress ticks during the 90s wait, and on
  failure a clear `LAUNCH DISPATCH FAILURE #N` line plus evidence from
  the Roblox-logs dir (`"no new Roblox player log was created at all"`
  vs `"new player log appeared - Roblox started then died"`).
- ✅ Clear distinction between **dispatch failure** (protocol handoff
  silently dropped — no `RobloxPlayerBeta.exe` ever appeared) and
  **crash-on-start** (process spawned, died within 60s) — two different
  failure modes with different log messages and recovery paths.
- ✅ Manual reconnect resets the dispatch-fail counter.

### v3.2.9
*Add the two UNIVERSAL server-disconnect patterns, derived from real
captured AFK-mirror logs.*
- 🐛 **22 June, 15:15 silent disconnect, ignored for 1h 27m.** The
  AFK PC's bambPserver shut down (reason code 288). The Roblox process
  stayed alive on the disconnect screen; `LogTailTick`'s
  `DetectDisconnectInLog` was checking too-specific phrases that didn't
  match what Roblox actually wrote:
  - log said `Disconnect with reason: 288` (numeric code) — script
    only matched `Disconnect with reason: Lost|Timeout|KickedFromGame`
  - log said `Client has been disconnected with reason: The server has
    shut down` — script had no equivalent pattern
  - log said `Lost connection with reason : The server has shut down`
    (note space before colon) — script only matched `Lost connection
    to the game` (different phrasing)
- ✨ **Universal patterns added** (verified against every captured
  disconnect we have on file):
  - `Client has been disconnected with reason`
  - `Lost connection with reason`
  These fire on EVERY real server-side disconnect (planned shutdown,
  logged-in-elsewhere, etc.) and are inherently teleport-safe (teleports
  don't emit them — the client initiates them, so no server reply).
- 📝 Documented that the `Error Code: NNN` patterns have never matched
  in any captured log (they're user-dialog text, not log text). Kept as
  defense-in-depth.
- 📝 Confirmed reason-code mapping from our own logs:
  - **285** = in-game teleport (paired with `UgcExperienceController:
    doTeleport`) — V3.2.7 debounce handles these.
  - **288** = real server shutdown (paired with `Client has been
    disconnected with reason: The server has shut down`).
  The web's "285 = server shutdown" claim is wrong (it conflates
  user-facing Error Code with internal RakNet reason).

### v3.2.8
*Hotfix: removes stray top-level `}` introduced by V3.2.7.*
- 🐛 V3.2.7 added an extra closing brace at top level (after
  `LogTailTick`'s closing brace) during the debounce-feature edit.
  AHK's `/validate` passed but the actual runtime threw
  `Unexpected "}"` on startup, preventing the script from loading.
- ✅ No behaviour change vs V3.2.7 — teleport-debounce feature intact
  and now actually runs.

### v3.2.7
*60-second teleport debounce on log-detected disconnects.*
- 🐛 Roblox emits `Disconnected from server` (with reason code 285)
  during legitimate in-game teleports — `TeleportService`, place-jumps,
  server hops. V3.2.6 and earlier fired an immediate reconnect on the
  first sighting, yanking the player out of a perfectly healthy
  teleport mid-flight. Observed live on bambPserver at 12:40:28 today
  (full reconnect cycle for what was just a normal server hop).
- ✨ **Pending-disconnect debounce.** When a disconnect log signal is
  detected, the script now holds it as "pending" for 60 s and confirms
  one of three outcomes:
  1. **Server re-join observed** (`Connection accepted from` in the log
     chunks) — teleport completed, clear pending, no reconnect fired.
  2. **Hold expires with no re-join** — real disconnect, reconnect
     fires with the original reason preserved (`log:<reason>`).
  3. **Roblox process dies during the hold** — clear pending; the
     process-exit branch in MonitorTick handles the relaunch directly
     (no duplicate trigger).
- 🛡 Pending state is also cleared on log-file rotation (fresh Roblox
  session) and at the entry of `TriggerReconnect` (any other path that
  reconnects supersedes the debounce).
- ⚠ Process-exit detection (the script's primary signal) is **not**
  debounced — when Roblox truly closes, MonitorTick still reacts
  promptly via the existing post-launch grace logic.

### v3.2.6
*Audit hotfix: tighten the V3.2.5 update-detection gate.*
Three reviewers caught four real gaps in V3.2.5; this release closes
them.
- 🐛 **Phantom LifetimeCrashes during updates.** MonitorTick incremented
  the crash counter and re-wrote stats.ini before the V3.2.5 deferral
  ran, so a 5-minute Roblox update polluted lifetime stats with ~60
  phantom crashes. Now gated.
- 🐛 **Disconnect-dialog signal lost during updates.** The error-dialog
  branch closed the dialog before deferring, leaving no trigger for the
  next tick to retry once the update finished. Now the dialog is left
  on-screen while updating and reused next tick.
- 🐛 **Manual-reconnect hotkey bypassed the gate.** Pressing the
  reconnect hotkey during an active install would still fire
  `roblox://` on top of the updater. `ReconnectToGame` now self-gates;
  a toast notifies the user the request was skipped.
- 🐛 **Deferral log spam.** "Roblox update in progress - deferring
  reconnect" was emitted on every 5 s monitor tick. Now throttled to
  once per 60 s (same throttle on the new dialog-deferral log).
- 🧹 Removed dead `ProcessExist("RobloxPlayerLauncherBeta.exe")` check
  from `IsRobloxUpdating()` — no such Roblox binary exists.

### v3.2.5
*Defer reconnects while Roblox is updating itself.*
- 🐛 Discovered cascade: a forced Roblox client update (0.725 → 0.726)
  could break the bootstrap for hours. Every `roblox://` URI invocation
  briefly spawned a `RobloxPlayerBeta.exe` then died (installer aborting),
  so the script saw "process appeared then exited" 57 times in 5 hours,
  each one opening a fresh VIP browser tab (≈57 unclosed tabs by morning).
- ✨ **`IsRobloxUpdating()` detector.** Returns true if
  `RobloxPlayerInstaller.exe` is running OR a
  `%LOCALAPPDATA%\Roblox\logs\RobloxPlayerInstaller_*.log` was modified
  in the last 120 s. Both signals are absent during a healthy session.
- 🛡 `TriggerReconnect` defers (logs `Roblox update in progress -
  deferring reconnect (no attempt consumed)`) instead of firing the URI
  / consuming an attempt / arming the cooldown when an update is live.
  Repeats every monitor tick; resumes automatically once the installer
  finishes.
- 🛡 `ReconnectToGame`'s V3.2.4 zombie-launcher killer now skips when an
  update is active — `RobloxPlayerLauncher.exe` IS the updater during a
  patch and must not be killed.

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
