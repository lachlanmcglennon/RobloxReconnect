; ============================================================================
; Roblox Auto-Reconnect Tool V3.1
; AutoHotkey v2 - Comprehensive GUI for Roblox session management
;
; V3.1 additions vs V3.0:
;   * Profile rotation on each reconnect, favorite flag, search/filter
;   * Profile import/export (JSON)
;   * Remember window size & position
;   * User-configurable hotkeys (rebind from Settings)
;   * Pause Anti-AFK during reconnect, sound volume slider
;   * Stop-after-N-reconnects safety cap, pause monitoring on battery power
;   * Mask VIP link in UI, hide links in logs (privacy)
;   * In-log search, success-rate stat, CSV export of stats
;   * Auto-update checker (GitHub releases API), Roblox status check
;   * Config backup on each save, tooltips on key controls
;   * Bug fixes: process priority mapping, log-tail trim
; ============================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent()
SetWorkingDir(A_ScriptDir)

; ====== Application Constants ======
global APP_NAME       := "Roblox Auto-Reconnect V3.1"
global APP_VERSION    := "3.1.0"
global APP_AUTHOR     := "INNIE (V3.1 Audit + Feature Pack)"
global APP_REPO       := "lachlanmcglennon/RobloxReconnect"
global DATA_DIR       := A_ScriptDir . "\RobloxReconnect-Data"
global CONFIG_FILE    := DATA_DIR . "\config.ini"
global PROFILES_FILE  := DATA_DIR . "\profiles.ini"
global STATS_FILE     := DATA_DIR . "\stats.ini"
global LOG_FILE       := DATA_DIR . "\app.log"
global CONFIG_BACKUP_DIR := DATA_DIR . "\config-backups"
global LOG_MAX_BYTES  := 512 * 1024  ; rotate at 512 KB
global MAX_LOG_VIEW_LINES := 500

; ====== State ======
global Profiles           := []   ; array of Maps: name, type, link, gameId, notes, fav
global ActiveProfileIdx   := 1
global IsMonitoringActive := false
global IsAntiAfkActive    := false
global IsAntiAfkPaused    := false  ; transient pause during reconnect
global ReconnectAttempts  := 0
global LastReconnectTime  := 0
global SessionStart       := A_TickCount
global LifetimeReconnects := 0
global LifetimeCrashes    := 0
global LifetimeSessions   := 0
global SuccessfulReconnects := 0      ; this session (for success rate)
global FailedReconnects     := 0
global CheckTimer         := ""
global RejoinTimer        := ""
global AntiAfkTimer       := ""
global StopAtTimer        := ""
global SleepPreventTimer  := ""
global BatteryCheckTimer  := ""
global VipMasked          := true     ; UI: VIP links shown as ••• until reveal
global ProfileFilterText  := ""

; ====== Config (populated by LoadConfig) ======
global Cfg := Map(
    "CheckIntervalSec",    5,
    "RejoinHours",         1,
    "RejoinMinutes",       0,
    "AutoRejoinEnabled",   false,
    "MaxAttempts",         0,              ; 0 = unlimited
    "CooldownSec",         10,
    "BackoffEnabled",      true,
    "JitterSec",           3,
    "InternetCheck",       true,
    "MinimizeAfterJoin",   false,
    "AlwaysOnTopRoblox",   false,
    "ProcessPriority",     "Normal",       ; Low, Normal, High
    "CloseBrowsers",       false,
    "BrowserList",         "chrome.exe,firefox.exe,msedge.exe,opera.exe,brave.exe,vivaldi.exe,iexplore.exe",
    "AntiAfkEnabled",      false,
    "AntiAfkMethod",       "Mouse",        ; Mouse, Key
    "AntiAfkIntervalSec",  120,
    "AntiAfkJitterSec",    30,
    "AntiAfkKey",          "Space",
    "AntiAfkOnlyFocused",  true,
    "AntiAfkPauseDuringReconnect", true,
    "SoundEnabled",        false,
    "SoundOnConnect",      "",
    "SoundOnDisconnect",   "",
    "SoundVolume",         100,            ; 0-100
    "DiscordEnabled",      false,
    "DiscordWebhook",      "",
    "NotifyOnConnect",     true,
    "NotifyOnDisconnect",  true,
    "NotifyOnError",       true,
    "TrayNotifications",   true,
    "MinimizeToTray",      true,
    "StartMinimized",      false,
    "AlwaysOnTopGui",      false,
    "AutoStartWithWindows",false,
    "DelayedStartSec",     0,
    "StopAtHHMM",          "",
    "PreventSleep",        true,
    "LogLevel",            "Info",         ; Debug, Info, Warn, Error
    "LogToFile",           true,
    "StartMonitoringOnLaunch", false,
    "ActiveProfile",       1,
    ; --- V3.1 additions ---
    "RotateProfiles",      false,
    "StopAfterReconnects", 0,              ; 0 = unlimited (lifetime safety cap)
    "PauseOnBattery",      false,
    "MaskVipLinks",        true,
    "HideLinksInLogs",     true,
    "BackupConfigOnSave",  true,
    "RememberWindowPos",   true,
    "WindowX",             -1,             ; -1 = unset
    "WindowY",             -1,
    "WindowW",             580,
    "WindowH",             580,
    "Hotkey_ToggleMonitor","F1",
    "Hotkey_Reconnect",    "F2",
    "Hotkey_Minimize",     "F3",
    "Hotkey_AntiAfk",      "F4",
    "Hotkey_Emergency",    "^+r",
    "Hotkey_Panic",        "^+q",
    "AutoUpdateCheck",     true
)

; ====== Bootstrap ======
EnsureDataDir()
LoadProfiles()
LoadConfig()
LoadStats()
LifetimeSessions += 1
SaveStats()

; ====== Build GUI ======
myGui := Gui("+Resize", APP_NAME)
myGui.MarginX := 10
myGui.MarginY := 10
myGui.SetFont("s9", "Segoe UI")
myGui.OnEvent("Close", GuiClose)
myGui.OnEvent("Size", GuiSize)

Tab := myGui.Add("Tab3", "w560 h520 vMainTab", [
    "Monitor", "Servers", "Window", "Anti-AFK",
    "Alerts", "Schedule", "Stats", "Logs", "Settings"])

; ---------- Monitor Tab ----------
Tab.UseTab(1)
myGui.Add("GroupBox", "x20 y40 w520 h200", "Connection Monitoring")

myGui.Add("Text", "x40 y70 w100", "Active Profile:")
ProfileDDL := myGui.Add("DropDownList", "x150 y67 w260 vActiveProfile")
ProfileDDL.OnEvent("Change", OnActiveProfileChange)
SwitchProfileBtn := myGui.Add("Button", "x420 y66 w110 h22", "Go To Profiles")
SwitchProfileBtn.OnEvent("Click", (*) => myGui["MainTab"].Value := 2)

myGui.Add("Text", "x40 y100 w100", "Status:")
StatusText := myGui.Add("Text", "x150 y100 w380 cRed", "Idle - monitoring disabled")

myGui.Add("Text", "x40 y130 w100", "Check every:")
CheckIntervalEdit := myGui.Add("Edit", "x150 y127 w60 h22 Number", Cfg["CheckIntervalSec"])
myGui.Add("Text", "x215 y130 w60", "seconds")
myGui.Add("Text", "x300 y130 w80", "Max attempts:")
MaxAttemptsEdit := myGui.Add("Edit", "x385 y127 w50 h22 Number", Cfg["MaxAttempts"])
myGui.Add("Text", "x440 y130 w90", "(0 = unlimited)")

myGui.Add("Text", "x40 y160 w100", "Cooldown:")
CooldownEdit := myGui.Add("Edit", "x150 y157 w60 h22 Number", Cfg["CooldownSec"])
myGui.Add("Text", "x215 y160 w40", "sec")
BackoffCheck := myGui.Add("Checkbox", "x270 y160 w160 vBackoff", "Exponential backoff")
BackoffCheck.Value := Cfg["BackoffEnabled"] ? 1 : 0
myGui.Add("Text", "x435 y160 w45", "Jitter:")
JitterEdit := myGui.Add("Edit", "x480 y157 w45 h22 Number", Cfg["JitterSec"])

InternetCheckBox := myGui.Add("Checkbox", "x40 y190 w200 vInternet", "Verify internet before reconnect")
InternetCheckBox.Value := Cfg["InternetCheck"] ? 1 : 0

myGui.Add("GroupBox", "x20 y260 w520 h120", "Controls")
StartBtn := myGui.Add("Button", "x40 y285 w120 h36", "▶ Start Monitoring")
StartBtn.OnEvent("Click", (*) => StartMonitoring())
StopBtn := myGui.Add("Button", "x170 y285 w120 h36", "■ Stop")
StopBtn.OnEvent("Click", (*) => StopMonitoring())
ReconnectBtn := myGui.Add("Button", "x300 y285 w120 h36", "↻ Reconnect Now")
ReconnectBtn.OnEvent("Click", (*) => ManualReconnect())
PanicBtn := myGui.Add("Button", "x430 y285 w100 h36", "✋ Panic Stop")
PanicBtn.OnEvent("Click", (*) => PanicStop())

myGui.Add("Text", "x40 y335 w500 cGray",
    "Hotkeys: F1 toggle monitor  •  F2 reconnect  •  F3 minimize  •  F4 anti-AFK  •  Ctrl+Shift+R emergency  •  Ctrl+Shift+Q panic")

; ---------- Servers Tab ----------
Tab.UseTab(2)
myGui.Add("GroupBox", "x20 y40 w520 h270", "Server Profiles")

myGui.Add("Text", "x30 y65 w50", "Filter:")
ProfileFilterEdit := myGui.Add("Edit", "x80 y62 w200 h22")
ProfileFilterEdit.OnEvent("Change", (*) => RefreshProfilesLV())
ImportProfBtn := myGui.Add("Button", "x290 y61 w110 h22", "Import…")
ImportProfBtn.OnEvent("Click", (*) => ImportProfilesJson())
ExportProfBtn := myGui.Add("Button", "x405 y61 w110 h22", "Export…")
ExportProfBtn.OnEvent("Click", (*) => ExportProfilesJson())

ProfilesLV := myGui.Add("ListView", "x30 y90 w500 h195 Grid -Multi vProfileLV",
    ["#", "★", "Name", "Type", "Target", "Notes"])
ProfilesLV.OnEvent("DoubleClick", (*) => EditProfile())
ProfilesLV.OnEvent("ItemSelect", (*) => UpdateProfileButtons())

AddProfBtn := myGui.Add("Button", "x30 y293 w70 h24", "Add")
AddProfBtn.OnEvent("Click", (*) => AddProfile())
EditProfBtn := myGui.Add("Button", "x105 y293 w70 h24", "Edit")
EditProfBtn.OnEvent("Click", (*) => EditProfile())
DupProfBtn := myGui.Add("Button", "x180 y293 w70 h24", "Duplicate")
DupProfBtn.OnEvent("Click", (*) => DuplicateProfile())
DelProfBtn := myGui.Add("Button", "x255 y293 w70 h24", "Delete")
DelProfBtn.OnEvent("Click", (*) => DeleteProfile())
SetActiveBtn := myGui.Add("Button", "x330 y293 w80 h24", "Set Active")
SetActiveBtn.OnEvent("Click", (*) => SetActiveFromLV())
FavBtn := myGui.Add("Button", "x415 y293 w55 h24", "★ Fav")
FavBtn.OnEvent("Click", (*) => ToggleFavSelected())
TestProfBtn := myGui.Add("Button", "x475 y293 w55 h24", "Test")
TestProfBtn.OnEvent("Click", (*) => TestSelectedProfile())

myGui.Add("GroupBox", "x20 y325 w520 h105", "Quick Actions on Active Profile")
CopyLinkBtn := myGui.Add("Button", "x40 y350 w120 h26", "📋 Copy Link")
CopyLinkBtn.OnEvent("Click", (*) => CopyActiveLink())
OpenBrowserBtn := myGui.Add("Button", "x170 y350 w150 h26", "🌐 Open in Browser")
OpenBrowserBtn.OnEvent("Click", (*) => OpenActiveInBrowser())
RandomProfBtn := myGui.Add("Button", "x330 y350 w160 h26", "🎲 Pick Random Profile")
RandomProfBtn.OnEvent("Click", (*) => PickRandomProfile())
RotateProfilesCheck := myGui.Add("Checkbox", "x40 y385 w280", "Rotate profiles on each reconnect")
RotateProfilesCheck.Value := Cfg["RotateProfiles"] ? 1 : 0
RevealLinkBtn := myGui.Add("Button", "x330 y383 w160 h22", "👁 Toggle reveal links")
RevealLinkBtn.OnEvent("Click", (*) => ToggleVipReveal())

; ---------- Window Tab ----------
Tab.UseTab(3)
myGui.Add("GroupBox", "x20 y40 w520 h170", "Roblox Window Behavior")
MinAfterJoinCheck := myGui.Add("Checkbox", "x40 y65 w400", "Minimize Roblox after joining (GPU saver)")
MinAfterJoinCheck.Value := Cfg["MinimizeAfterJoin"] ? 1 : 0
AlwaysTopRobloxCheck := myGui.Add("Checkbox", "x40 y90 w400", "Keep Roblox always-on-top")
AlwaysTopRobloxCheck.Value := Cfg["AlwaysOnTopRoblox"] ? 1 : 0
myGui.Add("Text", "x40 y120 w120", "Process priority:")
PriorityDDL := myGui.Add("DropDownList", "x160 y117 w100", ["Low", "Normal", "High"])
PriorityDDL.Text := Cfg["ProcessPriority"]
ApplyPrioBtn := myGui.Add("Button", "x270 y116 w130 h22", "Apply Now")
ApplyPrioBtn.OnEvent("Click", (*) => ApplyRobloxPriority())
MinimizeNowBtn := myGui.Add("Button", "x40 y150 w160 h28", "🔽 Minimize Roblox Now")
MinimizeNowBtn.OnEvent("Click", (*) => MinimizeRobloxWindows())
FocusRobloxBtn := myGui.Add("Button", "x210 y150 w160 h28", "🎯 Focus Roblox")
FocusRobloxBtn.OnEvent("Click", (*) => FocusRoblox())
KillRobloxBtn := myGui.Add("Button", "x380 y150 w150 h28", "💀 Force Kill Roblox")
KillRobloxBtn.OnEvent("Click", (*) => ForceKillRoblox())

myGui.Add("GroupBox", "x20 y225 w520 h170", "Browser Management")
CloseBrowsersCheck := myGui.Add("Checkbox", "x40 y250 w500", "Close web browsers after successful reconnection")
CloseBrowsersCheck.Value := Cfg["CloseBrowsers"] ? 1 : 0
myGui.Add("Text", "x40 y280 w500", "Browser executable list (comma-separated):")
BrowserListEdit := myGui.Add("Edit", "x40 y300 w480 h60", Cfg["BrowserList"])
CloseBrowsersNowBtn := myGui.Add("Button", "x40 y365 w200 h22", "Close Browsers Now")
CloseBrowsersNowBtn.OnEvent("Click", (*) => CloseBrowsers(true))

; ---------- Anti-AFK Tab ----------
Tab.UseTab(4)
myGui.Add("GroupBox", "x20 y40 w520 h220", "Anti-AFK Settings")
AntiAfkCheck := myGui.Add("Checkbox", "x40 y65 w400", "Enable Anti-AFK (keeps Roblox from idle-kicking you)")
AntiAfkCheck.Value := Cfg["AntiAfkEnabled"] ? 1 : 0
AntiAfkCheck.OnEvent("Click", (*) => ToggleAntiAfk(AntiAfkCheck.Value = 1))

myGui.Add("Text", "x40 y95 w100", "Method:")
AntiAfkMethodDDL := myGui.Add("DropDownList", "x150 y92 w120", ["Mouse", "Key"])
AntiAfkMethodDDL.Text := Cfg["AntiAfkMethod"]

myGui.Add("Text", "x40 y125 w100", "Key to press:")
AntiAfkKeyDDL := myGui.Add("DropDownList", "x150 y122 w120",
    ["Space", "w", "a", "s", "d", "Shift", "Ctrl", "F15"])
AntiAfkKeyDDL.Text := Cfg["AntiAfkKey"]

myGui.Add("Text", "x40 y155 w100", "Interval:")
AntiAfkIntervalEdit := myGui.Add("Edit", "x150 y152 w60 h22 Number", Cfg["AntiAfkIntervalSec"])
myGui.Add("Text", "x215 y155 w80", "seconds")
myGui.Add("Text", "x300 y155 w60", "± Jitter:")
AntiAfkJitterEdit := myGui.Add("Edit", "x360 y152 w60 h22 Number", Cfg["AntiAfkJitterSec"])
myGui.Add("Text", "x425 y155 w80", "seconds")

AntiAfkFocusCheck := myGui.Add("Checkbox", "x40 y185 w400", "Only run when Roblox window is focused")
AntiAfkFocusCheck.Value := Cfg["AntiAfkOnlyFocused"] ? 1 : 0

AntiAfkPauseReconCheck := myGui.Add("Checkbox", "x40 y210 w400", "Pause Anti-AFK during a reconnect")
AntiAfkPauseReconCheck.Value := Cfg["AntiAfkPauseDuringReconnect"] ? 1 : 0

AntiAfkTestBtn := myGui.Add("Button", "x40 y240 w200 h28", "🕹 Test Anti-AFK Once")
AntiAfkTestBtn.OnEvent("Click", (*) => DoAntiAfkAction(true))

; ---------- Alerts Tab ----------
Tab.UseTab(5)
myGui.Add("GroupBox", "x20 y40 w520 h160", "Notifications")
TrayNotifyCheck := myGui.Add("Checkbox", "x40 y65 w250", "Tray balloon notifications")
TrayNotifyCheck.Value := Cfg["TrayNotifications"] ? 1 : 0
NotifyConnCheck := myGui.Add("Checkbox", "x40 y90 w250", "Notify on successful connect")
NotifyConnCheck.Value := Cfg["NotifyOnConnect"] ? 1 : 0
NotifyDiscCheck := myGui.Add("Checkbox", "x40 y115 w250", "Notify on disconnect")
NotifyDiscCheck.Value := Cfg["NotifyOnDisconnect"] ? 1 : 0
NotifyErrCheck := myGui.Add("Checkbox", "x40 y140 w250", "Notify on errors")
NotifyErrCheck.Value := Cfg["NotifyOnError"] ? 1 : 0
TestTrayBtn := myGui.Add("Button", "x300 y65 w180 h28", "Test Tray Notification")
TestTrayBtn.OnEvent("Click", (*) => TrayNotify("Test", "This is a test notification from " . APP_NAME, "Info"))

myGui.Add("GroupBox", "x20 y210 w520 h90", "Sound Alerts")
SoundCheck := myGui.Add("Checkbox", "x40 y235 w300", "Enable sound alerts")
SoundCheck.Value := Cfg["SoundEnabled"] ? 1 : 0
myGui.Add("Text", "x40 y265 w100", "Connect .wav:")
SoundConnectEdit := myGui.Add("Edit", "x140 y262 w220 h22", Cfg["SoundOnConnect"])
BrowseSoundConnBtn := myGui.Add("Button", "x365 y261 w35 h22", "…")
BrowseSoundConnBtn.OnEvent("Click", (*) => BrowseSoundFile(SoundConnectEdit))
TestSoundBtn := myGui.Add("Button", "x405 y261 w45 h22", "Play")
TestSoundBtn.OnEvent("Click", (*) => PlaySoundFile(SoundConnectEdit.Text))
myGui.Add("Text", "x455 y265 w30", "Vol:")
SoundVolSlider := myGui.Add("Slider", "x485 y262 w50 Range0-100 ToolTip", Cfg["SoundVolume"])

myGui.Add("GroupBox", "x20 y310 w520 h100", "Discord Webhook")
DiscordCheck := myGui.Add("Checkbox", "x40 y335 w300", "Send alerts to Discord webhook")
DiscordCheck.Value := Cfg["DiscordEnabled"] ? 1 : 0
myGui.Add("Text", "x40 y365 w100", "Webhook URL:")
DiscordUrlEdit := myGui.Add("Edit", "x140 y362 w340 h22", Cfg["DiscordWebhook"])
TestDiscordBtn := myGui.Add("Button", "x485 y361 w50 h22", "Test")
TestDiscordBtn.OnEvent("Click", (*) => TestDiscord())

; ---------- Schedule Tab ----------
Tab.UseTab(6)
myGui.Add("GroupBox", "x20 y40 w520 h160", "Scheduled Auto-Rejoin")
AutoRejoinCheck := myGui.Add("Checkbox", "x40 y65 w300", "Enable auto-rejoin on schedule")
AutoRejoinCheck.Value := Cfg["AutoRejoinEnabled"] ? 1 : 0
myGui.Add("Text", "x40 y95 w100", "Every:")
RejoinHoursEdit := myGui.Add("Edit", "x150 y92 w60 h22 Number", Cfg["RejoinHours"])
myGui.Add("Text", "x215 y95 w50", "hours")
RejoinMinsEdit := myGui.Add("Edit", "x265 y92 w60 h22 Number", Cfg["RejoinMinutes"])
myGui.Add("Text", "x330 y95 w60", "minutes")
myGui.Add("Text", "x40 y130 w500 cGray",
    "Tip: Use auto-rejoin to stay on a fresh server instance. It will force-close and relaunch Roblox.")

myGui.Add("GroupBox", "x20 y210 w520 h220", "Startup & Shutdown")
AutoStartWinCheck := myGui.Add("Checkbox", "x40 y235 w400", "Start " . APP_NAME . " with Windows")
AutoStartWinCheck.Value := Cfg["AutoStartWithWindows"] ? 1 : 0
AutoStartWinCheck.OnEvent("Click", (*) => SetAutoStartWithWindows(AutoStartWinCheck.Value = 1))
StartMonOnLaunchCheck := myGui.Add("Checkbox", "x40 y260 w400", "Start monitoring automatically when app launches")
StartMonOnLaunchCheck.Value := Cfg["StartMonitoringOnLaunch"] ? 1 : 0
StartMinimizedCheck := myGui.Add("Checkbox", "x40 y285 w400", "Start app minimized to tray")
StartMinimizedCheck.Value := Cfg["StartMinimized"] ? 1 : 0

myGui.Add("Text", "x40 y315 w120", "Delayed start:")
DelayedStartEdit := myGui.Add("Edit", "x160 y312 w60 h22 Number", Cfg["DelayedStartSec"])
myGui.Add("Text", "x225 y315 w200", "seconds (0 = none)")

myGui.Add("Text", "x40 y345 w120", "Stop at time:")
StopAtEdit := myGui.Add("Edit", "x160 y342 w80 h22", Cfg["StopAtHHMM"])
myGui.Add("Text", "x245 y345 w300 cGray", "Format HH:MM (24h), blank to disable")

PreventSleepCheck := myGui.Add("Checkbox", "x40 y375 w300", "Prevent system sleep while monitoring")
PreventSleepCheck.Value := Cfg["PreventSleep"] ? 1 : 0
PauseOnBatteryCheck := myGui.Add("Checkbox", "x310 y375 w220", "Pause monitoring when on battery")
PauseOnBatteryCheck.Value := Cfg["PauseOnBattery"] ? 1 : 0

myGui.Add("Text", "x40 y400 w160", "Stop after N reconnects:")
StopAfterReconEdit := myGui.Add("Edit", "x205 y397 w60 h22 Number", Cfg["StopAfterReconnects"])
myGui.Add("Text", "x270 y400 w260 cGray", "0 = unlimited (lifetime safety cap)")

; ---------- Stats Tab ----------
Tab.UseTab(7)
myGui.Add("GroupBox", "x20 y40 w520 h350", "Session & Lifetime Statistics")
StatsText := myGui.Add("Edit", "x30 y65 w500 h310 ReadOnly VScroll", "Loading stats...")
RefreshStatsBtn := myGui.Add("Button", "x30 y390 w120 h28", "🔄 Refresh")
RefreshStatsBtn.OnEvent("Click", (*) => RefreshStats())
ResetStatsBtn := myGui.Add("Button", "x160 y390 w150 h28", "🧹 Reset Lifetime Stats")
ResetStatsBtn.OnEvent("Click", (*) => ResetLifetimeStats())
ExportStatsCsvBtn := myGui.Add("Button", "x320 y390 w150 h28", "📊 Export Stats CSV")
ExportStatsCsvBtn.OnEvent("Click", (*) => ExportStatsCsv())

; ---------- Logs Tab ----------
Tab.UseTab(8)
myGui.Add("GroupBox", "x20 y40 w520 h350", "Activity Log")
LogText := myGui.Add("Edit", "x30 y65 w500 h310 ReadOnly VScroll -Wrap", "")
myGui.Add("Text", "x30 y380 w50", "Search:")
LogSearchEdit := myGui.Add("Edit", "x80 y377 w140 h22")
LogSearchEdit.OnEvent("Change", (*) => RefreshLogView())
LogFilterDDL := myGui.Add("DropDownList", "x225 y377 w90", ["All", "Info", "Warn", "Error"])
LogFilterDDL.Text := "All"
LogFilterDDL.OnEvent("Change", (*) => RefreshLogView())
ClearLogBtn := myGui.Add("Button", "x320 y376 w55 h24", "Clear")
ClearLogBtn.OnEvent("Click", (*) => ClearLogView())
CopyLogBtn := myGui.Add("Button", "x380 y376 w55 h24", "Copy")
CopyLogBtn.OnEvent("Click", (*) => CopyLogToClipboard())
ExportLogBtn := myGui.Add("Button", "x440 y376 w50 h24", "Export")
ExportLogBtn.OnEvent("Click", (*) => ExportLog())
OpenLogFileBtn := myGui.Add("Button", "x495 y376 w55 h24", "File")
OpenLogFileBtn.OnEvent("Click", (*) => OpenLogFile())

; ---------- Settings Tab ----------
Tab.UseTab(9)
myGui.Add("GroupBox", "x20 y40 w520 h130", "Window & Behaviour")
MinToTrayCheck := myGui.Add("Checkbox", "x40 y65 w250", "Minimize to tray instead of taskbar")
MinToTrayCheck.Value := Cfg["MinimizeToTray"] ? 1 : 0
AlwaysTopGuiCheck := myGui.Add("Checkbox", "x300 y65 w230", "Keep this window always-on-top")
AlwaysTopGuiCheck.Value := Cfg["AlwaysOnTopGui"] ? 1 : 0
AlwaysTopGuiCheck.OnEvent("Click", (*) => ApplyAlwaysOnTopGui())
RememberPosCheck := myGui.Add("Checkbox", "x40 y90 w250", "Remember window size && position")
RememberPosCheck.Value := Cfg["RememberWindowPos"] ? 1 : 0
AutoUpdateCheck := myGui.Add("Checkbox", "x300 y90 w230", "Check for updates on startup")
AutoUpdateCheck.Value := Cfg["AutoUpdateCheck"] ? 1 : 0

myGui.Add("Text", "x40 y120 w70", "Log level:")
LogLevelDDL := myGui.Add("DropDownList", "x115 y117 w100", ["Debug", "Info", "Warn", "Error"])
LogLevelDDL.Text := Cfg["LogLevel"]
LogToFileCheck := myGui.Add("Checkbox", "x230 y120 w130", "Write log to file")
LogToFileCheck.Value := Cfg["LogToFile"] ? 1 : 0
HideLinksCheck := myGui.Add("Checkbox", "x370 y120 w160", "Hide links in logs")
HideLinksCheck.Value := Cfg["HideLinksInLogs"] ? 1 : 0
MaskVipCheck := myGui.Add("Checkbox", "x40 y145 w250", "Mask VIP links in UI (click-to-reveal)")
MaskVipCheck.Value := Cfg["MaskVipLinks"] ? 1 : 0
BackupCfgCheck := myGui.Add("Checkbox", "x300 y145 w230", "Back up config on every save")
BackupCfgCheck.Value := Cfg["BackupConfigOnSave"] ? 1 : 0

myGui.Add("GroupBox", "x20 y180 w520 h60", "Hotkeys")
HotkeysSummary := myGui.Add("Text", "x40 y200 w400 cGray", "")
RebindHotkeysBtn := myGui.Add("Button", "x440 y198 w90 h24", "Rebind…")
RebindHotkeysBtn.OnEvent("Click", (*) => HotkeyRebindDialog())

myGui.Add("GroupBox", "x20 y250 w520 h70", "Diagnostics")
SelfTestBtn := myGui.Add("Button", "x40 y270 w120 h28", "🩺 Self-test")
SelfTestBtn.OnEvent("Click", (*) => RunSelfTest())
RobloxStatusBtn := myGui.Add("Button", "x170 y270 w160 h28", "📡 Check Roblox Status")
RobloxStatusBtn.OnEvent("Click", (*) => CheckRobloxStatus(true))
CheckUpdatesBtn := myGui.Add("Button", "x340 y270 w180 h28", "⬆ Check for Updates Now")
CheckUpdatesBtn.OnEvent("Click", (*) => CheckForUpdates(true))

myGui.Add("GroupBox", "x20 y330 w520 h95", "Config Management")
SaveCfgBtn := myGui.Add("Button", "x40 y353 w120 h26", "💾 Save Settings")
SaveCfgBtn.OnEvent("Click", (*) => (PullCfgFromGui(), SaveConfig(), Log("Settings saved", "Info"), MsgBox("Settings saved!", APP_NAME, 64)))
ReloadCfgBtn := myGui.Add("Button", "x170 y353 w130 h26", "🔃 Reload from Disk")
ReloadCfgBtn.OnEvent("Click", (*) => (LoadConfig(), PushCfgToGui(), Log("Settings reloaded", "Info")))
ExportCfgBtn := myGui.Add("Button", "x310 y353 w90 h26", "📤 Export")
ExportCfgBtn.OnEvent("Click", (*) => ExportConfig())
ImportCfgBtn := myGui.Add("Button", "x405 y353 w85 h26", "📥 Import")
ImportCfgBtn.OnEvent("Click", (*) => ImportConfig())
ResetBtn := myGui.Add("Button", "x40 y388 w200 h26", "↺ Reset All to Defaults")
ResetBtn.OnEvent("Click", (*) => ResetDefaults())
OpenDataDirBtn := myGui.Add("Button", "x250 y388 w140 h26", "📁 Open Data Folder")
OpenDataDirBtn.OnEvent("Click", (*) => Run(DATA_DIR))
AboutBtn := myGui.Add("Button", "x400 y388 w90 h26", "ℹ About")
AboutBtn.OnEvent("Click", (*) => ShowAbout())

myGui.Add("Text", "x40 y430 w500 cGray",
    APP_NAME . " by " . APP_AUTHOR . "  •  Data dir: " . DATA_DIR)

; ---------- End Tabs ----------
Tab.UseTab()

; Bottom status strip
StatusBar := myGui.Add("StatusBar", , "Ready. Load or create a profile to begin.")

; Initialize GUI dynamic content
RefreshProfileDropDown()
RefreshProfilesLV()
UpdateProfileButtons()
RefreshStats()
RefreshLogView()
ApplyAlwaysOnTopGui()
RefreshHotkeysSummary()
InstallTooltips()

; ====== Tray Menu ======
A_TrayMenu.Delete()
A_TrayMenu.Add("Show Window", (*) => ShowMainWindow())
A_TrayMenu.Add("Start Monitoring", (*) => StartMonitoring())
A_TrayMenu.Add("Stop Monitoring", (*) => StopMonitoring())
A_TrayMenu.Add("Reconnect Now", (*) => ManualReconnect())
A_TrayMenu.Add()
A_TrayMenu.Add("Minimize Roblox", (*) => MinimizeRobloxWindows())
A_TrayMenu.Add("Focus Roblox", (*) => FocusRoblox())
A_TrayMenu.Add()
A_TrayMenu.Add("Exit " . APP_NAME, (*) => ExitApp())
A_TrayMenu.Default := "Show Window"
A_IconTip := APP_NAME . " (idle)"

; ====== Hotkeys ======
RegisterHotkeys()

; ====== Show / Launch ======
ShowOpts := BuildShowOptions()
if (Cfg["StartMinimized"] && Cfg["MinimizeToTray"]) {
    myGui.Show("Hide " . ShowOpts)
} else {
    myGui.Show(ShowOpts)
}

Log("=== " . APP_NAME . " started ===", "Info")
Log("Data folder: " . DATA_DIR, "Debug")

; Apply scheduling
ApplyStopAtTimer()
ApplyBatteryWatcher()

if (Cfg["AutoUpdateCheck"])
    SetTimer(() => CheckForUpdates(false), -3000)

if (Cfg["DelayedStartSec"] > 0 && Cfg["StartMonitoringOnLaunch"]) {
    SetTimer(() => StartMonitoring(), -1 * Cfg["DelayedStartSec"] * 1000)
    Log("Delayed start scheduled in " . Cfg["DelayedStartSec"] . "s", "Info")
} else if (Cfg["StartMonitoringOnLaunch"]) {
    SetTimer(() => StartMonitoring(), -500)
}

; ============================================================================
; =====================  Function implementations  ===========================
; ============================================================================

; ---------- Filesystem / Config ----------

EnsureDataDir() {
    global DATA_DIR
    if (!DirExist(DATA_DIR)) {
        try {
            DirCreate(DATA_DIR)
        } catch Error as e {
            ; fall back to script dir silently
        }
    }
}

LoadConfig() {
    global Cfg, CONFIG_FILE, ActiveProfileIdx
    if (!FileExist(CONFIG_FILE))
        return
    for key, defaultVal in Cfg.Clone() {
        try {
            val := IniRead(CONFIG_FILE, "Config", key, "__MISSING__")
            if (val = "__MISSING__")
                continue
            ; bool BEFORE int (false/true are also Integers in v2)
            if (defaultVal == true || defaultVal == false)
                Cfg[key] := (val = "1" || val = "true" || val = "True")
            else if (defaultVal is Integer)
                Cfg[key] := Integer(val)
            else if (defaultVal is Float)
                Cfg[key] := Float(val)
            else if (defaultVal is Number)
                Cfg[key] := val + 0
            else
                Cfg[key] := val
        } catch Error as e {
            ; skip bad key
        }
    }
    ActiveProfileIdx := Cfg["ActiveProfile"]
    if (ActiveProfileIdx < 1 || ActiveProfileIdx > Profiles.Length)
        ActiveProfileIdx := Profiles.Length ? 1 : 0
}

SaveConfig() {
    global Cfg, CONFIG_FILE, ActiveProfileIdx
    EnsureDataDir()
    Cfg["ActiveProfile"] := ActiveProfileIdx
    if (Cfg["BackupConfigOnSave"] && FileExist(CONFIG_FILE))
        BackupConfigFile()
    for key, val in Cfg {
        try {
            if (val == true)
                s := "1"
            else if (val == false)
                s := "0"
            else
                s := val
            IniWrite(s, CONFIG_FILE, "Config", key)
        } catch Error as e {
            ; ignore
        }
    }
}

BackupConfigFile() {
    global CONFIG_FILE, CONFIG_BACKUP_DIR
    try {
        if (!DirExist(CONFIG_BACKUP_DIR))
            DirCreate(CONFIG_BACKUP_DIR)
        ts := FormatTime(, "yyyyMMdd-HHmmss")
        FileCopy(CONFIG_FILE, CONFIG_BACKUP_DIR . "\config-" . ts . ".ini", 1)
        ; Prune to last 20 backups
        files := []
        Loop Files, CONFIG_BACKUP_DIR . "\config-*.ini"
            files.Push({path: A_LoopFilePath, time: A_LoopFileTimeModified})
        if (files.Length > 20) {
            ; sort ascending by time, delete oldest
            Loop files.Length - 1 {
                i := A_Index
                Loop files.Length - i {
                    j := A_Index
                    if (files[j].time > files[j+1].time) {
                        tmp := files[j], files[j] := files[j+1], files[j+1] := tmp
                    }
                }
            }
            Loop files.Length - 20
                try FileDelete(files[A_Index].path)
        }
    } catch Error as e {
        ; ignore
    }
}

LoadProfiles() {
    global Profiles, PROFILES_FILE
    Profiles := []
    if (!FileExist(PROFILES_FILE))
        return
    try {
        countStr := IniRead(PROFILES_FILE, "Profiles", "Count", "0")
        count := Integer(countStr)
        Loop count {
            section := "Profile" . A_Index
            p := Map(
                "name",   IniRead(PROFILES_FILE, section, "Name",   "Profile " . A_Index),
                "type",   IniRead(PROFILES_FILE, section, "Type",   "private"),
                "link",   IniRead(PROFILES_FILE, section, "Link",   ""),
                "gameId", IniRead(PROFILES_FILE, section, "GameId", ""),
                "notes",  IniRead(PROFILES_FILE, section, "Notes",  ""),
                "fav",    IniRead(PROFILES_FILE, section, "Fav",    "0") = "1"
            )
            Profiles.Push(p)
        }
    } catch Error as e {
        ; file corrupted; leave empty
    }
}

SaveProfiles() {
    global Profiles, PROFILES_FILE
    EnsureDataDir()
    try {
        if (FileExist(PROFILES_FILE))
            FileDelete(PROFILES_FILE)
    } catch Error as e {
        ; ignore
    }
    try {
        IniWrite(Profiles.Length, PROFILES_FILE, "Profiles", "Count")
        for i, p in Profiles {
            section := "Profile" . i
            IniWrite(p["name"],   PROFILES_FILE, section, "Name")
            IniWrite(p["type"],   PROFILES_FILE, section, "Type")
            IniWrite(p["link"],   PROFILES_FILE, section, "Link")
            IniWrite(p["gameId"], PROFILES_FILE, section, "GameId")
            IniWrite(p["notes"],  PROFILES_FILE, section, "Notes")
            IniWrite(p.Has("fav") && p["fav"] ? "1" : "0", PROFILES_FILE, section, "Fav")
        }
    } catch Error as e {
        Log("Error saving profiles: " . e.Message, "Error")
    }
}

LoadStats() {
    global STATS_FILE, LifetimeReconnects, LifetimeCrashes, LifetimeSessions
    if (!FileExist(STATS_FILE))
        return
    try {
        LifetimeReconnects := Integer(IniRead(STATS_FILE, "Lifetime", "Reconnects", "0"))
        LifetimeCrashes    := Integer(IniRead(STATS_FILE, "Lifetime", "Crashes",    "0"))
        LifetimeSessions   := Integer(IniRead(STATS_FILE, "Lifetime", "Sessions",   "0"))
    } catch Error as e {
        ; ignore
    }
}

SaveStats() {
    global STATS_FILE, LifetimeReconnects, LifetimeCrashes, LifetimeSessions
    EnsureDataDir()
    try {
        IniWrite(LifetimeReconnects, STATS_FILE, "Lifetime", "Reconnects")
        IniWrite(LifetimeCrashes,    STATS_FILE, "Lifetime", "Crashes")
        IniWrite(LifetimeSessions,   STATS_FILE, "Lifetime", "Sessions")
    } catch Error as e {
        ; ignore
    }
}

ResetLifetimeStats() {
    global LifetimeReconnects, LifetimeCrashes, LifetimeSessions
    if (MsgBox("Really reset lifetime statistics?", APP_NAME, 4 + 48) != "Yes")
        return
    LifetimeReconnects := 0
    LifetimeCrashes := 0
    LifetimeSessions := 1
    SaveStats()
    RefreshStats()
    Log("Lifetime stats reset", "Warn")
}

; ---------- Config <-> GUI ----------

PullCfgFromGui() {
    global Cfg
    Cfg["CheckIntervalSec"]    := Integer(CheckIntervalEdit.Text)
    Cfg["MaxAttempts"]         := Integer(MaxAttemptsEdit.Text)
    Cfg["CooldownSec"]         := Integer(CooldownEdit.Text)
    Cfg["BackoffEnabled"]      := (BackoffCheck.Value = 1)
    Cfg["JitterSec"]           := Integer(JitterEdit.Text)
    Cfg["InternetCheck"]       := (InternetCheckBox.Value = 1)
    Cfg["MinimizeAfterJoin"]   := (MinAfterJoinCheck.Value = 1)
    Cfg["AlwaysOnTopRoblox"]   := (AlwaysTopRobloxCheck.Value = 1)
    Cfg["ProcessPriority"]     := PriorityDDL.Text
    Cfg["CloseBrowsers"]       := (CloseBrowsersCheck.Value = 1)
    Cfg["BrowserList"]         := BrowserListEdit.Text
    Cfg["AntiAfkEnabled"]      := (AntiAfkCheck.Value = 1)
    Cfg["AntiAfkMethod"]       := AntiAfkMethodDDL.Text
    Cfg["AntiAfkIntervalSec"]  := Integer(AntiAfkIntervalEdit.Text)
    Cfg["AntiAfkJitterSec"]    := Integer(AntiAfkJitterEdit.Text)
    Cfg["AntiAfkKey"]          := AntiAfkKeyDDL.Text
    Cfg["AntiAfkOnlyFocused"]  := (AntiAfkFocusCheck.Value = 1)
    Cfg["AntiAfkPauseDuringReconnect"] := (AntiAfkPauseReconCheck.Value = 1)
    Cfg["SoundEnabled"]        := (SoundCheck.Value = 1)
    Cfg["SoundOnConnect"]      := SoundConnectEdit.Text
    Cfg["SoundVolume"]         := Integer(SoundVolSlider.Value)
    Cfg["DiscordEnabled"]      := (DiscordCheck.Value = 1)
    Cfg["DiscordWebhook"]      := DiscordUrlEdit.Text
    Cfg["NotifyOnConnect"]     := (NotifyConnCheck.Value = 1)
    Cfg["NotifyOnDisconnect"]  := (NotifyDiscCheck.Value = 1)
    Cfg["NotifyOnError"]       := (NotifyErrCheck.Value = 1)
    Cfg["TrayNotifications"]   := (TrayNotifyCheck.Value = 1)
    Cfg["MinimizeToTray"]      := (MinToTrayCheck.Value = 1)
    Cfg["StartMinimized"]      := (StartMinimizedCheck.Value = 1)
    Cfg["AlwaysOnTopGui"]      := (AlwaysTopGuiCheck.Value = 1)
    Cfg["AutoStartWithWindows"]:= (AutoStartWinCheck.Value = 1)
    Cfg["DelayedStartSec"]     := Integer(DelayedStartEdit.Text)
    Cfg["StopAtHHMM"]          := StopAtEdit.Text
    Cfg["PreventSleep"]        := (PreventSleepCheck.Value = 1)
    Cfg["PauseOnBattery"]      := (PauseOnBatteryCheck.Value = 1)
    Cfg["StopAfterReconnects"] := Integer(StopAfterReconEdit.Text)
    Cfg["LogLevel"]            := LogLevelDDL.Text
    Cfg["LogToFile"]           := (LogToFileCheck.Value = 1)
    Cfg["HideLinksInLogs"]     := (HideLinksCheck.Value = 1)
    Cfg["MaskVipLinks"]        := (MaskVipCheck.Value = 1)
    Cfg["BackupConfigOnSave"]  := (BackupCfgCheck.Value = 1)
    Cfg["RememberWindowPos"]   := (RememberPosCheck.Value = 1)
    Cfg["AutoUpdateCheck"]     := (AutoUpdateCheck.Value = 1)
    Cfg["StartMonitoringOnLaunch"] := (StartMonOnLaunchCheck.Value = 1)
    Cfg["AutoRejoinEnabled"]   := (AutoRejoinCheck.Value = 1)
    Cfg["RejoinHours"]         := Integer(RejoinHoursEdit.Text)
    Cfg["RejoinMinutes"]       := Integer(RejoinMinsEdit.Text)
    Cfg["RotateProfiles"]      := (RotateProfilesCheck.Value = 1)
}

PushCfgToGui() {
    global Cfg
    CheckIntervalEdit.Text    := Cfg["CheckIntervalSec"]
    MaxAttemptsEdit.Text      := Cfg["MaxAttempts"]
    CooldownEdit.Text         := Cfg["CooldownSec"]
    BackoffCheck.Value        := Cfg["BackoffEnabled"] ? 1 : 0
    JitterEdit.Text           := Cfg["JitterSec"]
    InternetCheckBox.Value    := Cfg["InternetCheck"] ? 1 : 0
    MinAfterJoinCheck.Value   := Cfg["MinimizeAfterJoin"] ? 1 : 0
    AlwaysTopRobloxCheck.Value:= Cfg["AlwaysOnTopRoblox"] ? 1 : 0
    PriorityDDL.Text          := Cfg["ProcessPriority"]
    CloseBrowsersCheck.Value  := Cfg["CloseBrowsers"] ? 1 : 0
    BrowserListEdit.Text      := Cfg["BrowserList"]
    AntiAfkCheck.Value        := Cfg["AntiAfkEnabled"] ? 1 : 0
    AntiAfkMethodDDL.Text     := Cfg["AntiAfkMethod"]
    AntiAfkIntervalEdit.Text  := Cfg["AntiAfkIntervalSec"]
    AntiAfkJitterEdit.Text    := Cfg["AntiAfkJitterSec"]
    AntiAfkKeyDDL.Text        := Cfg["AntiAfkKey"]
    AntiAfkFocusCheck.Value   := Cfg["AntiAfkOnlyFocused"] ? 1 : 0
    AntiAfkPauseReconCheck.Value := Cfg["AntiAfkPauseDuringReconnect"] ? 1 : 0
    SoundCheck.Value          := Cfg["SoundEnabled"] ? 1 : 0
    SoundConnectEdit.Text     := Cfg["SoundOnConnect"]
    SoundVolSlider.Value      := Cfg["SoundVolume"]
    DiscordCheck.Value        := Cfg["DiscordEnabled"] ? 1 : 0
    DiscordUrlEdit.Text       := Cfg["DiscordWebhook"]
    NotifyConnCheck.Value     := Cfg["NotifyOnConnect"] ? 1 : 0
    NotifyDiscCheck.Value     := Cfg["NotifyOnDisconnect"] ? 1 : 0
    NotifyErrCheck.Value      := Cfg["NotifyOnError"] ? 1 : 0
    TrayNotifyCheck.Value     := Cfg["TrayNotifications"] ? 1 : 0
    MinToTrayCheck.Value      := Cfg["MinimizeToTray"] ? 1 : 0
    StartMinimizedCheck.Value := Cfg["StartMinimized"] ? 1 : 0
    AlwaysTopGuiCheck.Value   := Cfg["AlwaysOnTopGui"] ? 1 : 0
    AutoStartWinCheck.Value   := Cfg["AutoStartWithWindows"] ? 1 : 0
    DelayedStartEdit.Text     := Cfg["DelayedStartSec"]
    StopAtEdit.Text           := Cfg["StopAtHHMM"]
    PreventSleepCheck.Value   := Cfg["PreventSleep"] ? 1 : 0
    PauseOnBatteryCheck.Value := Cfg["PauseOnBattery"] ? 1 : 0
    StopAfterReconEdit.Text   := Cfg["StopAfterReconnects"]
    LogLevelDDL.Text          := Cfg["LogLevel"]
    LogToFileCheck.Value      := Cfg["LogToFile"] ? 1 : 0
    HideLinksCheck.Value      := Cfg["HideLinksInLogs"] ? 1 : 0
    MaskVipCheck.Value        := Cfg["MaskVipLinks"] ? 1 : 0
    BackupCfgCheck.Value      := Cfg["BackupConfigOnSave"] ? 1 : 0
    RememberPosCheck.Value    := Cfg["RememberWindowPos"] ? 1 : 0
    AutoUpdateCheck.Value     := Cfg["AutoUpdateCheck"] ? 1 : 0
    StartMonOnLaunchCheck.Value := Cfg["StartMonitoringOnLaunch"] ? 1 : 0
    AutoRejoinCheck.Value     := Cfg["AutoRejoinEnabled"] ? 1 : 0
    RejoinHoursEdit.Text      := Cfg["RejoinHours"]
    RejoinMinsEdit.Text       := Cfg["RejoinMinutes"]
    RotateProfilesCheck.Value := Cfg["RotateProfiles"] ? 1 : 0
    RefreshHotkeysSummary()
}

ExportConfig() {
    global CONFIG_FILE
    PullCfgFromGui()
    SaveConfig()
    dest := FileSelect("S", , "Export config", "INI (*.ini)")
    if (!dest)
        return
    try {
        FileCopy(CONFIG_FILE, dest, 1)
        MsgBox("Config exported to:`n" . dest, APP_NAME, 64)
    } catch Error as e {
        MsgBox("Export failed: " . e.Message, APP_NAME, 16)
    }
}

ImportConfig() {
    global CONFIG_FILE
    src := FileSelect(1, , "Import config", "INI (*.ini)")
    if (!src)
        return
    try {
        FileCopy(src, CONFIG_FILE, 1)
        LoadConfig()
        PushCfgToGui()
        MsgBox("Config imported.", APP_NAME, 64)
    } catch Error as e {
        MsgBox("Import failed: " . e.Message, APP_NAME, 16)
    }
}

ResetDefaults() {
    global Cfg
    if (MsgBox("Reset ALL settings to defaults? Profiles will be kept.", APP_NAME, 4 + 48) != "Yes")
        return
    Cfg := Map(
        "CheckIntervalSec",5, "RejoinHours",1, "RejoinMinutes",0, "AutoRejoinEnabled",false,
        "MaxAttempts",0, "CooldownSec",10, "BackoffEnabled",true, "JitterSec",3,
        "InternetCheck",true, "MinimizeAfterJoin",false, "AlwaysOnTopRoblox",false,
        "ProcessPriority","Normal", "CloseBrowsers",false,
        "BrowserList","chrome.exe,firefox.exe,msedge.exe,opera.exe,brave.exe,vivaldi.exe,iexplore.exe",
        "AntiAfkEnabled",false, "AntiAfkMethod","Mouse", "AntiAfkIntervalSec",120,
        "AntiAfkJitterSec",30, "AntiAfkKey","Space", "AntiAfkOnlyFocused",true,
        "AntiAfkPauseDuringReconnect",true,
        "SoundEnabled",false, "SoundOnConnect","", "SoundOnDisconnect","", "SoundVolume",100,
        "DiscordEnabled",false, "DiscordWebhook","",
        "NotifyOnConnect",true, "NotifyOnDisconnect",true, "NotifyOnError",true,
        "TrayNotifications",true, "MinimizeToTray",true, "StartMinimized",false,
        "AlwaysOnTopGui",false, "AutoStartWithWindows",false, "DelayedStartSec",0,
        "StopAtHHMM","", "PreventSleep",true, "LogLevel","Info", "LogToFile",true,
        "StartMonitoringOnLaunch",false, "ActiveProfile",1,
        "RotateProfiles",false, "StopAfterReconnects",0, "PauseOnBattery",false,
        "MaskVipLinks",true, "HideLinksInLogs",true, "BackupConfigOnSave",true,
        "RememberWindowPos",true, "WindowX",-1, "WindowY",-1, "WindowW",580, "WindowH",580,
        "Hotkey_ToggleMonitor","F1", "Hotkey_Reconnect","F2", "Hotkey_Minimize","F3",
        "Hotkey_AntiAfk","F4", "Hotkey_Emergency","^+r", "Hotkey_Panic","^+q",
        "AutoUpdateCheck",true
    )
    SaveConfig()
    PushCfgToGui()
    RegisterHotkeys()
    Log("Settings reset to defaults", "Warn")
}

ApplyAlwaysOnTopGui() {
    global Cfg
    try {
        if (Cfg["AlwaysOnTopGui"])
            WinSetAlwaysOnTop(1, "ahk_id " . myGui.Hwnd)
        else
            WinSetAlwaysOnTop(0, "ahk_id " . myGui.Hwnd)
    } catch Error as e {
        ; ignore
    }
}

SetAutoStartWithWindows(enable) {
    regKey := "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
    valueName := "RobloxReconnectV3"
    try {
        if (enable) {
            cmd := '"' . A_ScriptFullPath . '"'
            RegWrite(cmd, "REG_SZ", regKey, valueName)
            Log("Enabled Windows auto-start", "Info")
        } else {
            try {
                RegDelete(regKey, valueName)
            } catch Error as e {
                ; not present is fine
            }
            Log("Disabled Windows auto-start", "Info")
        }
    } catch Error as e {
        MsgBox("Could not update Windows auto-start: " . e.Message, APP_NAME, 16)
    }
}

; ---------- Validation / helpers ----------

IsValidVipLink(link) {
    link := Trim(link)
    if (link = "")
        return false
    if (RegExMatch(link, "i)^https://(www\.)?roblox\.com/"))
        return true
    if (RegExMatch(link, "i)^roblox://"))
        return true
    return false
}

IsValidGameId(id) {
    return RegExMatch(Trim(id), "^\d+$")
}

GetActiveProfile() {
    global Profiles, ActiveProfileIdx
    if (Profiles.Length = 0 || ActiveProfileIdx < 1 || ActiveProfileIdx > Profiles.Length)
        return ""
    return Profiles[ActiveProfileIdx]
}

GetProfileTarget(p) {
    if (!p)
        return ""
    if (p["type"] = "private")
        return p["link"]
    return "https://www.roblox.com/games/" . p["gameId"]
}

CheckInternet() {
    try {
        http := ComObject("WinHttp.WinHttpRequest.5.1")
        http.SetTimeouts(3000, 3000, 3000, 3000)
        http.Open("GET", "https://www.google.com/generate_204", false)
        http.Send()
        return true
    } catch Error as e {
        return false
    }
}

; ---------- Profile CRUD ----------

RefreshProfileDropDown() {
    global Profiles, ActiveProfileIdx
    items := []
    for i, p in Profiles
        items.Push(i . ". " . p["name"] . " [" . p["type"] . "]")
    ProfileDDL.Delete()
    if (items.Length > 0) {
        ProfileDDL.Add(items)
        if (ActiveProfileIdx < 1 || ActiveProfileIdx > Profiles.Length)
            ActiveProfileIdx := 1
        ProfileDDL.Choose(ActiveProfileIdx)
    }
}

RefreshProfilesLV() {
    global Profiles
    ProfilesLV.Delete()
    filter := ""
    try filter := ProfileFilterEdit.Text
    filterLower := StrLower(filter)
    for i, p in Profiles {
        if (filterLower != "") {
            hay := StrLower(p["name"] . " " . p["type"] . " " . p["notes"] . " " . p["link"] . " " . p["gameId"])
            if (!InStr(hay, filterLower))
                continue
        }
        target := p["type"] = "private" ? MaskVipForView(p["link"]) : "Game " . p["gameId"]
        if (StrLen(target) > 60)
            target := SubStr(target, 1, 57) . "..."
        star := (p.Has("fav") && p["fav"]) ? "★" : ""
        ProfilesLV.Add(, i, star, p["name"], p["type"], target, p["notes"])
    }
    Loop 6
        ProfilesLV.ModifyCol(A_Index, "AutoHdr")
}

MaskVipForView(link) {
    global Cfg, VipMasked
    if (link = "")
        return ""
    if (Cfg.Has("MaskVipLinks") && Cfg["MaskVipLinks"] && VipMasked)
        return "•••••••• [click 'reveal' to view]"
    return link
}

ToggleVipReveal() {
    global VipMasked
    VipMasked := !VipMasked
    RefreshProfilesLV()
    StatusBar.SetText(VipMasked ? "VIP links masked" : "VIP links revealed")
}

ToggleFavSelected() {
    row := ProfilesLV.GetNext(0)
    if (!row)
        return
    realIdx := GetRealProfileIndex(row)
    if (realIdx < 1)
        return
    p := Profiles[realIdx]
    p["fav"] := !(p.Has("fav") && p["fav"])
    Profiles[realIdx] := p
    SaveProfiles()
    RefreshProfilesLV()
}

GetRealProfileIndex(lvRow) {
    ; The "#" column holds the real profile index (since filter may hide rows)
    try {
        idxText := ProfilesLV.GetText(lvRow, 1)
        return Integer(idxText)
    } catch Error as e {
        return -1
    }
}

UpdateProfileButtons() {
    hasSel := ProfilesLV.GetNext(0) > 0
    EditProfBtn.Enabled := hasSel
    DupProfBtn.Enabled := hasSel
    DelProfBtn.Enabled := hasSel
    SetActiveBtn.Enabled := hasSel
    TestProfBtn.Enabled := hasSel
}

OnActiveProfileChange(*) {
    global ActiveProfileIdx
    sel := ProfileDDL.Value
    if (sel > 0) {
        ActiveProfileIdx := sel
        SaveConfig()
        p := GetActiveProfile()
        if (p)
            StatusBar.SetText("Active profile: " . p["name"])
    }
}

SetActiveFromLV() {
    global ActiveProfileIdx
    row := ProfilesLV.GetNext(0)
    if (!row)
        return
    real := GetRealProfileIndex(row)
    if (real < 1)
        return
    ActiveProfileIdx := real
    RefreshProfileDropDown()
    SaveConfig()
    Log("Active profile set to #" . real, "Info")
}

AddProfile() {
    p := ProfileDialog(Map("name", "New Profile", "type", "private", "link", "", "gameId", "", "notes", "", "fav", false))
    if (!p)
        return
    Profiles.Push(p)
    SaveProfiles()
    RefreshProfilesLV()
    RefreshProfileDropDown()
    Log("Added profile: " . p["name"], "Info")
}

EditProfile() {
    row := ProfilesLV.GetNext(0)
    if (!row)
        return
    real := GetRealProfileIndex(row)
    if (real < 1)
        return
    updated := ProfileDialog(Profiles[real])
    if (!updated)
        return
    Profiles[real] := updated
    SaveProfiles()
    RefreshProfilesLV()
    RefreshProfileDropDown()
    Log("Edited profile: " . updated["name"], "Info")
}

DuplicateProfile() {
    row := ProfilesLV.GetNext(0)
    if (!row)
        return
    real := GetRealProfileIndex(row)
    if (real < 1)
        return
    p := Profiles[real].Clone()
    p["name"] := p["name"] . " (copy)"
    Profiles.Push(p)
    SaveProfiles()
    RefreshProfilesLV()
    RefreshProfileDropDown()
}

DeleteProfile() {
    global ActiveProfileIdx
    row := ProfilesLV.GetNext(0)
    if (!row)
        return
    real := GetRealProfileIndex(row)
    if (real < 1)
        return
    if (MsgBox("Delete profile '" . Profiles[real]["name"] . "'?", APP_NAME, 4 + 48) != "Yes")
        return
    Profiles.RemoveAt(real)
    if (ActiveProfileIdx > Profiles.Length)
        ActiveProfileIdx := Profiles.Length
    SaveProfiles()
    RefreshProfilesLV()
    RefreshProfileDropDown()
    Log("Deleted profile #" . real, "Warn")
}

TestSelectedProfile() {
    row := ProfilesLV.GetNext(0)
    if (!row)
        return
    real := GetRealProfileIndex(row)
    if (real < 1)
        return
    p := Profiles[real]
    target := GetProfileTarget(p)
    if (p["type"] = "private" && !IsValidVipLink(p["link"])) {
        MsgBox("Invalid VIP link. Must start with https://www.roblox.com/ or roblox://", APP_NAME, 48)
        return
    }
    if (p["type"] = "public" && !IsValidGameId(p["gameId"])) {
        MsgBox("Invalid Game ID (digits only).", APP_NAME, 48)
        return
    }
    Log("Testing profile: " . p["name"], "Info")
    try {
        Run(target)
    } catch Error as e {
        MsgBox("Run failed: " . e.Message, APP_NAME, 16)
        return
    }
    Sleep(2000)
    if (ProcessExist("RobloxPlayerBeta.exe"))
        MsgBox("Roblox is starting. Profile looks good!", APP_NAME, 64)
    else
        MsgBox("Roblox did not appear to start - double-check the target.", APP_NAME, 48)
}

PickRandomProfile() {
    global Profiles, ActiveProfileIdx
    if (Profiles.Length = 0)
        return
    ActiveProfileIdx := Random(1, Profiles.Length)
    RefreshProfileDropDown()
    SaveConfig()
    Log("Random profile selected: " . Profiles[ActiveProfileIdx]["name"], "Info")
}

CopyActiveLink() {
    p := GetActiveProfile()
    if (!p) {
        MsgBox("No active profile.", APP_NAME, 48)
        return
    }
    A_Clipboard := GetProfileTarget(p)
    StatusBar.SetText("Copied target to clipboard")
}

OpenActiveInBrowser() {
    p := GetActiveProfile()
    if (!p)
        return
    url := GetProfileTarget(p)
    try {
        Run(url)
    } catch Error as e {
        MsgBox("Open failed: " . e.Message, APP_NAME, 16)
    }
}

ProfileDialog(initial) {
    dlg := Gui("+Owner" . myGui.Hwnd . " +ToolWindow", "Profile")
    dlg.SetFont("s9", "Segoe UI")
    dlg.MarginX := 10
    dlg.MarginY := 10
    dlg.Add("Text", "x10 y10 w80", "Name:")
    nameE := dlg.Add("Edit", "x100 y8 w320 h22", initial["name"])
    dlg.Add("Text", "x10 y40 w80", "Type:")
    typePrivR := dlg.Add("Radio", "x100 y40 w100 " . (initial["type"] = "private" ? "Checked" : ""), "Private/VIP")
    typePubR := dlg.Add("Radio", "x210 y40 w100 " . (initial["type"] = "public" ? "Checked" : ""), "Public")
    favCheck := dlg.Add("Checkbox", "x320 y40 w100", "★ Favorite")
    favCheck.Value := (initial.Has("fav") && initial["fav"]) ? 1 : 0
    dlg.Add("Text", "x10 y70 w80", "VIP Link:")
    linkE := dlg.Add("Edit", "x100 y68 w320 h22", initial["link"])
    dlg.Add("Text", "x10 y100 w80", "Game ID:")
    gidE := dlg.Add("Edit", "x100 y98 w160 h22", initial["gameId"])
    dlg.Add("Text", "x10 y130 w80", "Notes:")
    notesE := dlg.Add("Edit", "x100 y128 w320 h60 Multi", initial["notes"])
    result := ""
    okB := dlg.Add("Button", "x250 y200 w80 h26 Default", "OK")
    cancelB := dlg.Add("Button", "x340 y200 w80 h26", "Cancel")
    okB.OnEvent("Click", okClick)
    cancelB.OnEvent("Click", cancelClick)
    dlg.OnEvent("Close", cancelClick)
    dlg.Show("w440 h240")
    WinWaitClose("ahk_id " . dlg.Hwnd)
    return result

    okClick(*) {
        name := Trim(nameE.Text)
        type := (typePrivR.Value = 1) ? "private" : "public"
        link := Trim(linkE.Text)
        gid := Trim(gidE.Text)
        if (name = "") {
            MsgBox("Name is required.", APP_NAME, 48)
            return
        }
        if (type = "private" && link != "" && !IsValidVipLink(link)) {
            MsgBox("Invalid VIP link format.", APP_NAME, 48)
            return
        }
        if (type = "public" && gid != "" && !IsValidGameId(gid)) {
            MsgBox("Game ID must be digits only.", APP_NAME, 48)
            return
        }
        result := Map("name", name, "type", type, "link", link, "gameId", gid,
            "notes", notesE.Text, "fav", favCheck.Value = 1)
        dlg.Destroy()
    }
    cancelClick(*) {
        result := ""
        dlg.Destroy()
    }
}

; ---------- Monitoring lifecycle ----------

StartMonitoring(*) {
    global IsMonitoringActive, CheckTimer, RejoinTimer, SleepPreventTimer, Cfg, ReconnectAttempts
    if (IsMonitoringActive)
        return
    PullCfgFromGui()
    SaveConfig()
    p := GetActiveProfile()
    if (!p) {
        MsgBox("Create or select a profile first (Servers tab).", APP_NAME, 48)
        return
    }
    if (p["type"] = "private" && !IsValidVipLink(p["link"])) {
        MsgBox("Active profile has no valid VIP link.", APP_NAME, 48)
        return
    }
    if (p["type"] = "public" && !IsValidGameId(p["gameId"])) {
        MsgBox("Active profile has no valid Game ID.", APP_NAME, 48)
        return
    }
    IsMonitoringActive := true
    ReconnectAttempts := 0
    intervalMs := Cfg["CheckIntervalSec"] * 1000
    CheckTimer := MonitorTick
    SetTimer(CheckTimer, intervalMs)

    if (Cfg["AutoRejoinEnabled"]) {
        totalMs := (Cfg["RejoinHours"] * 3600000) + (Cfg["RejoinMinutes"] * 60000)
        if (totalMs > 0) {
            RejoinTimer := AutoRejoinTick
            SetTimer(RejoinTimer, totalMs)
            Log("Auto-rejoin enabled every " . Cfg["RejoinHours"] . "h " . Cfg["RejoinMinutes"] . "m", "Info")
        }
    }

    if (Cfg["PreventSleep"]) {
        PreventSleep(true)
        SleepPreventTimer := () => PreventSleep(true)
        SetTimer(SleepPreventTimer, 45000)
    }

    if (Cfg["AntiAfkEnabled"])
        ToggleAntiAfk(true)

    StatusText.Text := "Monitoring ACTIVE - profile: " . p["name"]
    StatusText.Opt("+cGreen")
    StatusBar.SetText("Monitoring started")
    A_IconTip := APP_NAME . " (monitoring)"
    Log("Monitoring started on profile: " . p["name"], "Info")
    TrayNotify(APP_NAME, "Monitoring started on '" . p["name"] . "'", "Info")
}

StopMonitoring(*) {
    global IsMonitoringActive, CheckTimer, RejoinTimer, SleepPreventTimer
    if (!IsMonitoringActive)
        return
    IsMonitoringActive := false
    if (CheckTimer) {
        try SetTimer(CheckTimer, 0)
        CheckTimer := ""
    }
    if (RejoinTimer) {
        try SetTimer(RejoinTimer, 0)
        RejoinTimer := ""
    }
    if (SleepPreventTimer) {
        try SetTimer(SleepPreventTimer, 0)
        SleepPreventTimer := ""
        PreventSleep(false)
    }
    StatusText.Text := "Idle - monitoring disabled"
    StatusText.Opt("+cRed")
    StatusBar.SetText("Monitoring stopped")
    A_IconTip := APP_NAME . " (idle)"
    Log("Monitoring stopped", "Info")
}

ToggleMonitoring(*) {
    if (IsMonitoringActive)
        StopMonitoring()
    else
        StartMonitoring()
}

PanicStop(*) {
    global IsAntiAfkActive
    StopMonitoring()
    if (IsAntiAfkActive)
        ToggleAntiAfk(false)
    if (StopAtTimer) {
        try SetTimer(StopAtTimer, 0)
    }
    Log("PANIC STOP - all automation halted", "Warn")
    TrayNotify(APP_NAME, "All automation stopped", "Warn")
}

EmergencyReconnect(*) {
    Log("Emergency reconnect triggered", "Warn")
    ManualReconnect()
}

MonitorTick() {
    global IsMonitoringActive, LifetimeCrashes
    if (!IsMonitoringActive)
        return
    try {
        if (!ProcessExist("RobloxPlayerBeta.exe")) {
            LifetimeCrashes += 1
            SaveStats()
            Log("Roblox not running - triggering reconnect", "Warn")
            TriggerReconnect("process exit")
            return
        }
        if (WinExist("ahk_class #32770 ahk_exe RobloxPlayerBeta.exe")) {
            txt := ""
            try {
                txt := WinGetText("ahk_class #32770 ahk_exe RobloxPlayerBeta.exe")
            } catch Error as e {
                ;
            }
            if (InStr(txt, "disconnect") || InStr(txt, "Disconnect")
                || InStr(txt, "lost connection") || InStr(txt, "error code")
                || InStr(txt, "Reconnect")) {
                Log("Error dialog detected - triggering reconnect", "Warn")
                try WinClose("ahk_class #32770 ahk_exe RobloxPlayerBeta.exe")
                Sleep(800)
                TriggerReconnect("error dialog")
                return
            }
        }
        wins := WinGetList("ahk_exe RobloxPlayerBeta.exe")
        for hwnd in wins {
            try {
                title := WinGetTitle("ahk_id " . hwnd)
                if (InStr(title, "Disconnected") || InStr(title, "Lost connection") || InStr(title, "Error")) {
                    Log("Disconnect title detected: " . title, "Warn")
                    TriggerReconnect("window title")
                    return
                }
            } catch Error as e {
                ;
            }
        }
    } catch Error as e {
        Log("MonitorTick error: " . e.Message, "Error")
    }
}

TriggerReconnect(reason) {
    global LastReconnectTime, ReconnectAttempts, Cfg
    now := A_TickCount
    cooldownMs := Cfg["CooldownSec"] * 1000
    if (Cfg["BackoffEnabled"] && ReconnectAttempts > 0)
        cooldownMs := cooldownMs * (2 ** Min(ReconnectAttempts, 5))
    if (LastReconnectTime > 0 && (now - LastReconnectTime) < cooldownMs) {
        Log("In cooldown (" . Round((cooldownMs - (now - LastReconnectTime)) / 1000) . "s remaining), skipping", "Debug")
        return
    }
    if (Cfg["MaxAttempts"] > 0 && ReconnectAttempts >= Cfg["MaxAttempts"]) {
        Log("Max attempts (" . Cfg["MaxAttempts"] . ") reached - stopping", "Error")
        StopMonitoring()
        Notify("error", APP_NAME, "Max reconnect attempts reached")
        return
    }
    ReconnectAttempts += 1
    LastReconnectTime := now
    Log("Reconnect #" . ReconnectAttempts . " reason: " . reason, "Info")
    ReconnectToGame()
}

AutoRejoinTick() {
    Log("Scheduled auto-rejoin triggered", "Info")
    TriggerReconnect("scheduled")
}

ManualReconnect(*) {
    global ReconnectAttempts, LastReconnectTime
    ReconnectAttempts := 0
    LastReconnectTime := 0
    ReconnectToGame()
}

ReconnectToGame() {
    global Cfg, LifetimeReconnects, Profiles, ActiveProfileIdx, IsAntiAfkPaused
    global SuccessfulReconnects, FailedReconnects
    if (Cfg["RotateProfiles"] && Profiles.Length > 1) {
        ActiveProfileIdx := Mod(ActiveProfileIdx, Profiles.Length) + 1
        try RefreshProfileDropDown()
    }
    p := GetActiveProfile()
    if (!p) {
        Log("No active profile - cannot reconnect", "Error")
        return
    }
    target := GetProfileTarget(p)
    if (p["type"] = "private" && !IsValidVipLink(p["link"])) {
        Log("Invalid VIP link on active profile", "Error")
        return
    }
    if (p["type"] = "public" && !IsValidGameId(p["gameId"])) {
        Log("Invalid Game ID on active profile", "Error")
        return
    }
    if (Cfg["InternetCheck"] && !CheckInternet()) {
        Log("No internet - deferring reconnect 15s", "Warn")
        SetTimer(() => ReconnectToGame(), -15000)
        return
    }
    if (Cfg["AntiAfkPauseDuringReconnect"] && IsAntiAfkActive)
        IsAntiAfkPaused := true
    Log("Reconnecting to " . p["name"] . " ...", "Info")
    Notify("disconnect", APP_NAME, "Reconnecting to " . p["name"])
    try {
        if (ProcessExist("RobloxPlayerBeta.exe")) {
            ProcessClose("RobloxPlayerBeta.exe")
            Sleep(1500)
            Loop 10 {
                if (!ProcessExist("RobloxPlayerBeta.exe"))
                    break
                Sleep(400)
            }
        }
        jitter := Cfg["JitterSec"] > 0 ? Random(0, Cfg["JitterSec"] * 1000) : 0
        Sleep(1000 + jitter)
        Run(target)
        Loop 30 {
            if (ProcessExist("RobloxPlayerBeta.exe")) {
                Log("Roblox launched, waiting for load...", "Info")
                Sleep(8000)
                LifetimeReconnects += 1
                SuccessfulReconnects += 1
                SaveStats()
                Log("Joined " . p["name"] . " successfully", "Info")
                Notify("connect", APP_NAME, "Joined " . p["name"])
                PostJoinHooks()
                IsAntiAfkPaused := false
                CheckLifetimeStopCap()
                return
            }
            Sleep(1000)
        }
        FailedReconnects += 1
        Log("Roblox did not start within 30s", "Error")
        Notify("error", APP_NAME, "Roblox did not start within 30s")
        IsAntiAfkPaused := false
    } catch Error as e {
        FailedReconnects += 1
        Log("Reconnect error: " . e.Message, "Error")
        Notify("error", APP_NAME, "Reconnect error: " . e.Message)
        IsAntiAfkPaused := false
    }
}

CheckLifetimeStopCap() {
    global Cfg, SuccessfulReconnects
    cap := Cfg["StopAfterReconnects"]
    if (cap > 0 && SuccessfulReconnects >= cap) {
        Log("Stop-after-N cap (" . cap . ") reached - stopping monitor", "Warn")
        StopMonitoring()
        Notify("error", APP_NAME, "Reconnect cap reached (" . cap . "). Monitoring stopped.")
    }
}

PostJoinHooks() {
    global Cfg
    if (Cfg["CloseBrowsers"])
        CloseBrowsers(false)
    if (Cfg["MinimizeAfterJoin"])
        MinimizeRobloxWindows()
    if (Cfg["AlwaysOnTopRoblox"])
        SetRobloxAlwaysOnTop(true)
    if (Cfg["ProcessPriority"] != "Normal")
        ApplyRobloxPriority()
}

; ---------- Window helpers ----------

MinimizeRobloxWindows(*) {
    count := 0
    try {
        wins := WinGetList("ahk_exe RobloxPlayerBeta.exe")
        for hwnd in wins {
            try {
                WinMinimize("ahk_id " . hwnd)
                count += 1
            } catch Error as e {
                ;
            }
        }
    } catch Error as e {
        Log("Minimize error: " . e.Message, "Error")
    }
    if (count > 0)
        Log("Minimized " . count . " Roblox window(s)", "Info")
}

FocusRoblox(*) {
    try {
        if (WinExist("ahk_exe RobloxPlayerBeta.exe"))
            WinActivate("ahk_exe RobloxPlayerBeta.exe")
    } catch Error as e {
        Log("Focus error: " . e.Message, "Error")
    }
}

SetRobloxAlwaysOnTop(on) {
    try {
        wins := WinGetList("ahk_exe RobloxPlayerBeta.exe")
        for hwnd in wins {
            try WinSetAlwaysOnTop(on ? 1 : 0, "ahk_id " . hwnd)
        }
    } catch Error as e {
        ;
    }
}

ApplyRobloxPriority(*) {
    global Cfg
    prio := Cfg["ProcessPriority"]
    ; AHK v2 ProcessSetPriority expects letter codes
    mapping := Map("Low", "L", "Normal", "N", "High", "H")
    if (!mapping.Has(prio))
        prio := "Normal"
    try {
        wins := WinGetList("ahk_exe RobloxPlayerBeta.exe")
        for hwnd in wins {
            try {
                pid := WinGetPID("ahk_id " . hwnd)
                ProcessSetPriority(mapping[prio], pid)
            } catch Error as e {
                ;
            }
        }
        Log("Set Roblox priority to " . prio, "Info")
    } catch Error as e {
        ;
    }
}

ForceKillRoblox(*) {
    if (MsgBox("Force-kill all Roblox processes?", APP_NAME, 4 + 48) != "Yes")
        return
    try {
        Loop 5 {
            if (!ProcessExist("RobloxPlayerBeta.exe"))
                break
            ProcessClose("RobloxPlayerBeta.exe")
            Sleep(400)
        }
        Log("Force-killed Roblox", "Warn")
    } catch Error as e {
        Log("Force kill error: " . e.Message, "Error")
    }
}

CloseBrowsers(verbose) {
    global Cfg
    list := StrSplit(Cfg["BrowserList"], ",", " `t")
    closed := 0
    for exe in list {
        exe := Trim(exe)
        if (exe = "")
            continue
        try {
            if (ProcessExist(exe)) {
                ProcessClose(exe)
                closed += 1
                if (verbose)
                    Log("Closed " . exe, "Info")
                Sleep(200)
            }
        } catch Error as e {
            ;
        }
    }
    if (verbose || closed > 0)
        Log(closed . " browser(s) closed", "Info")
}

PreventSleep(on) {
    ; ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED
    static ES_CONTINUOUS := 0x80000000, ES_SYSTEM := 0x00000001, ES_DISPLAY := 0x00000002
    try {
        if (on)
            DllCall("kernel32\SetThreadExecutionState", "UInt", ES_CONTINUOUS | ES_SYSTEM | ES_DISPLAY)
        else
            DllCall("kernel32\SetThreadExecutionState", "UInt", ES_CONTINUOUS)
    } catch Error as e {
        ;
    }
}

; ---------- Anti-AFK ----------

ToggleAntiAfk(on) {
    global IsAntiAfkActive, AntiAfkTimer, Cfg
    if (on && !IsAntiAfkActive) {
        IsAntiAfkActive := true
        AntiAfkCheck.Value := 1
        ScheduleNextAntiAfk()
        Log("Anti-AFK enabled", "Info")
    } else if (!on && IsAntiAfkActive) {
        IsAntiAfkActive := false
        AntiAfkCheck.Value := 0
        if (AntiAfkTimer) {
            try SetTimer(AntiAfkTimer, 0)
            AntiAfkTimer := ""
        }
        Log("Anti-AFK disabled", "Info")
    }
}

ScheduleNextAntiAfk() {
    global Cfg, AntiAfkTimer
    base := Cfg["AntiAfkIntervalSec"]
    jit := Cfg["AntiAfkJitterSec"]
    wait := base + (jit > 0 ? Random(-jit, jit) : 0)
    if (wait < 5)
        wait := 5
    AntiAfkTimer := AntiAfkTick
    SetTimer(AntiAfkTimer, -1 * wait * 1000)
}

AntiAfkTick() {
    global IsAntiAfkActive
    if (!IsAntiAfkActive)
        return
    DoAntiAfkAction(false)
    ScheduleNextAntiAfk()
}

DoAntiAfkAction(manual) {
    global Cfg, IsAntiAfkPaused
    if (!manual && IsAntiAfkPaused)
        return
    if (Cfg["AntiAfkOnlyFocused"] && !manual) {
        if (!WinActive("ahk_exe RobloxPlayerBeta.exe"))
            return
    }
    try {
        if (Cfg["AntiAfkMethod"] = "Mouse") {
            MouseGetPos(&mx, &my)
            MouseMove(mx + 2, my + 2, 0)
            Sleep(40)
            MouseMove(mx, my, 0)
        } else {
            key := Cfg["AntiAfkKey"]
            Send("{" . key . " down}")
            Sleep(50)
            Send("{" . key . " up}")
        }
        Log("Anti-AFK: " . Cfg["AntiAfkMethod"], "Debug")
    } catch Error as e {
        Log("Anti-AFK error: " . e.Message, "Error")
    }
}

; ---------- Notifications / Alerts ----------

Notify(kind, title, message) {
    global Cfg
    shouldNotify := true
    if (kind = "connect" && !Cfg["NotifyOnConnect"])
        shouldNotify := false
    if (kind = "disconnect" && !Cfg["NotifyOnDisconnect"])
        shouldNotify := false
    if (kind = "error" && !Cfg["NotifyOnError"])
        shouldNotify := false
    if (!shouldNotify)
        return
    TrayNotify(title, message, kind = "error" ? "Error" : kind = "connect" ? "Info" : "Warn")
    if (Cfg["SoundEnabled"]) {
        f := kind = "connect" ? Cfg["SoundOnConnect"] : Cfg["SoundOnDisconnect"]
        if (f != "")
            PlaySoundFile(f)
    }
    if (Cfg["DiscordEnabled"] && Cfg["DiscordWebhook"] != "")
        SendDiscord(title . " - " . message)
}

TrayNotify(title, message, level := "Info") {
    global Cfg
    if (!Cfg["TrayNotifications"])
        return
    iconFlag := (level = "Error") ? 0x3 : (level = "Warn") ? 0x2 : 0x1
    try {
        TrayTip(message, title, iconFlag)
    } catch Error as e {
        ;
    }
}

PlaySoundFile(path) {
    global Cfg
    if (path = "" || !FileExist(path))
        return
    try {
        SoundPlay(path)
        ; Apply volume preference (best-effort, AHK v2)
        try {
            vol := Cfg.Has("SoundVolume") ? Cfg["SoundVolume"] : 100
            if (vol < 100)
                SoundSetVolume(vol)  ; system master; falls back silently
        } catch Error as ev {
            ;
        }
    } catch Error as e {
        Log("Sound play error: " . e.Message, "Error")
    }
}

BrowseSoundFile(editCtl) {
    file := FileSelect(1, , "Select .wav file", "Audio (*.wav;*.mp3)")
    if (file) {
        editCtl.Text := file
    }
}

SendDiscord(message) {
    global Cfg
    try {
        payload := '{"content":"' . EscapeJson(message) . '","username":"' . APP_NAME . '"}'
        http := ComObject("WinHttp.WinHttpRequest.5.1")
        http.SetTimeouts(4000, 4000, 4000, 4000)
        http.Open("POST", Cfg["DiscordWebhook"], true)
        http.SetRequestHeader("Content-Type", "application/json")
        http.Send(payload)
    } catch Error as e {
        Log("Discord send failed: " . e.Message, "Error")
    }
}

EscapeJson(s) {
    s := StrReplace(s, "\", "\\")
    s := StrReplace(s, '"', '\"')
    s := StrReplace(s, "`n", "\n")
    s := StrReplace(s, "`r", "\r")
    s := StrReplace(s, "`t", "\t")
    return s
}

TestDiscord() {
    Cfg["DiscordWebhook"] := DiscordUrlEdit.Text
    if (Cfg["DiscordWebhook"] = "") {
        MsgBox("Enter a webhook URL first.", APP_NAME, 48)
        return
    }
    SendDiscord("✅ Test message from " . APP_NAME)
    MsgBox("Test sent (check your Discord channel).", APP_NAME, 64)
}

; ---------- Logging ----------

LogLevelRank(l) {
    switch l {
        case "Debug": return 0
        case "Info":  return 1
        case "Warn":  return 2
        case "Error": return 3
    }
    return 1
}

Log(message, level := "Info") {
    global Cfg, LOG_FILE, LOG_MAX_BYTES
    if (LogLevelRank(level) < LogLevelRank(Cfg["LogLevel"]))
        return
    if (Cfg.Has("HideLinksInLogs") && Cfg["HideLinksInLogs"])
        message := SanitizeForLog(message)
    ts := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    line := "[" . ts . "] [" . level . "] " . message
    AppendLogToView(line)
    if (!Cfg["LogToFile"])
        return
    try {
        if (FileExist(LOG_FILE) && FileGetSize(LOG_FILE) > LOG_MAX_BYTES) {
            try FileDelete(LOG_FILE . ".old")
            try FileMove(LOG_FILE, LOG_FILE . ".old", 1)
        }
        FileAppend(line . "`n", LOG_FILE)
    } catch Error as e {
        ;
    }
}

SanitizeForLog(s) {
    ; Replace VIP private-server URLs with redacted form
    s := RegExReplace(s, "i)https?://(www\.)?roblox\.com/[^\s]*privateServer[^\s]*", "https://roblox.com/[REDACTED-VIP]")
    s := RegExReplace(s, "i)roblox://[^\s]+", "roblox://[REDACTED]")
    s := RegExReplace(s, "i)linkCode=[A-Za-z0-9_\-]+", "linkCode=[REDACTED]")
    s := RegExReplace(s, "i)accessCode=[A-Za-z0-9_\-]+", "accessCode=[REDACTED]")
    return s
}

AppendLogToView(line) {
    global MAX_LOG_VIEW_LINES
    try {
        current := LogText.Text
        lines := StrSplit(current, "`n")
        if (lines.Length > MAX_LOG_VIEW_LINES) {
            ; Keep newest (MAX_LOG_VIEW_LINES - 50) lines from top (newest are prepended)
            kept := []
            keep := MAX_LOG_VIEW_LINES - 50
            Loop Min(keep, lines.Length)
                kept.Push(lines[A_Index])
            current := ""
            for ln in kept
                current .= ln . "`n"
        }
        LogText.Text := line . "`n" . current
    } catch Error as e {
        ;
    }
}

RefreshLogView() {
    global LOG_FILE
    LogText.Text := ""
    if (!FileExist(LOG_FILE))
        return
    try {
        content := FileRead(LOG_FILE)
        filter := LogFilterDDL.Text
        searchTerm := ""
        try searchTerm := LogSearchEdit.Text
        searchLower := StrLower(searchTerm)
        out := ""
        Loop Parse, content, "`n", "`r" {
            if (filter != "All" && !InStr(A_LoopField, "[" . filter . "]"))
                continue
            if (searchLower != "" && !InStr(StrLower(A_LoopField), searchLower))
                continue
            out := A_LoopField . "`n" . out
        }
        LogText.Text := out
    } catch Error as e {
        ;
    }
}

ClearLogView(*) {
    LogText.Text := ""
    try {
        if (FileExist(LOG_FILE))
            FileDelete(LOG_FILE)
    } catch Error as e {
        ;
    }
    Log("Log cleared by user", "Warn")
}

CopyLogToClipboard(*) {
    A_Clipboard := LogText.Text
    StatusBar.SetText("Log copied to clipboard")
}

ExportLog() {
    dest := FileSelect("S", , "Export log", "Text (*.txt)")
    if (!dest)
        return
    try {
        FileAppend(LogText.Text, dest)
        MsgBox("Exported log to:`n" . dest, APP_NAME, 64)
    } catch Error as e {
        MsgBox("Export failed: " . e.Message, APP_NAME, 16)
    }
}

OpenLogFile() {
    if (FileExist(LOG_FILE))
        Run(LOG_FILE)
    else
        MsgBox("No log file yet.", APP_NAME, 48)
}

; ---------- Stats ----------

RefreshStats() {
    global SessionStart, ReconnectAttempts, LifetimeReconnects, LifetimeCrashes, LifetimeSessions
    global SuccessfulReconnects, FailedReconnects
    uptimeMs := A_TickCount - SessionStart
    sessions := LifetimeSessions > 0 ? LifetimeSessions : 1
    avgPerSession := Round(LifetimeReconnects / sessions, 2)
    totalAttempts := SuccessfulReconnects + FailedReconnects
    successRate := totalAttempts > 0 ? Round(100.0 * SuccessfulReconnects / totalAttempts, 1) : 0
    s := ""
    s .= "=== Session ===`r`n"
    s .= "Uptime:             " . FormatDuration(uptimeMs) . "`r`n"
    s .= "Monitoring:         " . (IsMonitoringActive ? "ON" : "OFF") . "`r`n"
    s .= "Anti-AFK:           " . (IsAntiAfkActive ? (IsAntiAfkPaused ? "PAUSED" : "ON") : "OFF") . "`r`n"
    s .= "Reconnect attempts: " . ReconnectAttempts . "`r`n"
    s .= "Successful joins:   " . SuccessfulReconnects . "`r`n"
    s .= "Failed joins:       " . FailedReconnects . "`r`n"
    s .= "Success rate:       " . successRate . "%`r`n"
    s .= "`r`n"
    s .= "=== Lifetime ===`r`n"
    s .= "Sessions launched:  " . LifetimeSessions . "`r`n"
    s .= "Total reconnects:   " . LifetimeReconnects . "`r`n"
    s .= "Crashes detected:   " . LifetimeCrashes . "`r`n"
    s .= "Avg reconnects/run: " . avgPerSession . "`r`n"
    s .= "`r`n"
    s .= "=== Active Profile ===`r`n"
    p := GetActiveProfile()
    if (p) {
        s .= "Name:   " . p["name"] . "`r`n"
        s .= "Type:   " . p["type"] . "`r`n"
        s .= "Target: " . MaskVipForView(GetProfileTarget(p)) . "`r`n"
        if (p.Has("fav") && p["fav"])
            s .= "★ Favorite`r`n"
    } else {
        s .= "(none)`r`n"
    }
    StatsText.Text := s
}

FormatDuration(ms) {
    totalSec := ms // 1000
    h := totalSec // 3600
    m := (totalSec // 60) // 1 - (h * 60)
    sec := totalSec - (h * 3600) - (m * 60)
    return Format("{:02}:{:02}:{:02}", h, m, sec)
}

; ---------- Schedule: stop-at-time ----------

ApplyStopAtTimer() {
    global Cfg, StopAtTimer
    if (StopAtTimer) {
        try SetTimer(StopAtTimer, 0)
        StopAtTimer := ""
    }
    hhmm := Cfg["StopAtHHMM"]
    if (hhmm = "" || !RegExMatch(hhmm, "^(\d{1,2}):(\d{2})$", &m))
        return
    hh := Integer(m[1]), mm := Integer(m[2])
    now := A_Now
    target := SubStr(now, 1, 8) . Format("{:02}{:02}", hh, mm) . "00"
    diffSec := DateDiff(target, now, "S")
    if (diffSec < 0)
        diffSec += 86400
    if (diffSec <= 0)
        return
    StopAtTimer := () => (Log("Stop-at-time reached", "Warn"), StopMonitoring())
    SetTimer(StopAtTimer, -1 * diffSec * 1000)
    Log("Stop scheduled in " . diffSec . "s", "Info")
}

; ---------- GUI event handlers ----------

ShowAbout() {
    MsgBox(
        APP_NAME . "`n" .
        "Version " . APP_VERSION . "`n`n" .
        "A GUI tool for keeping your Roblox session alive -`n" .
        "auto-reconnect, anti-AFK, scheduling, Discord alerts,`n" .
        "multi-profile servers, and much more.`n`n" .
        "Repo: github.com/" . APP_REPO . "`n" .
        "Author: " . APP_AUTHOR . "`n" .
        "Data folder: " . DATA_DIR,
        "About " . APP_NAME, 64)
}

ShowMainWindow() {
    myGui.Show()
    WinActivate("ahk_id " . myGui.Hwnd)
}

GuiClose(*) {
    global Cfg
    PullCfgFromGui()
    SaveWindowGeometry()
    SaveConfig()
    SaveStats()
    if (Cfg["MinimizeToTray"]) {
        myGui.Hide()
        return true  ; prevent default close
    }
    ExitApp()
}

SaveWindowGeometry() {
    global Cfg
    if (!Cfg.Has("RememberWindowPos") || !Cfg["RememberWindowPos"])
        return
    try {
        WinGetPos(&x, &y, &w, &h, "ahk_id " . myGui.Hwnd)
        Cfg["WindowX"] := x
        Cfg["WindowY"] := y
        Cfg["WindowW"] := w
        Cfg["WindowH"] := h
    } catch Error as e {
        ;
    }
}

GuiSize(guiObj, minMax, width, height) {
    try {
        Tab.Move(, , width - 20, height - 50)
    } catch Error as e {
        ;
    }
}

; ============================================================================
; Initialize tray icon tooltip update & periodic stats refresh
; ============================================================================

SetTimer(() => (IsMonitoringActive ? RefreshStats() : 0), 5000)

; ============================================================================
; =====================  V3.1 helper functions  ==============================
; ============================================================================

; ---------- Hotkeys ----------

RegisterHotkeys() {
    global Cfg
    static last := Map()
    bindings := Map(
        "Hotkey_ToggleMonitor", (*) => ToggleMonitoring(),
        "Hotkey_Reconnect",     (*) => ManualReconnect(),
        "Hotkey_Minimize",      (*) => MinimizeRobloxWindows(),
        "Hotkey_AntiAfk",       (*) => ToggleAntiAfk(!IsAntiAfkActive),
        "Hotkey_Emergency",     (*) => EmergencyReconnect(),
        "Hotkey_Panic",         (*) => PanicStop()
    )
    ; Disable previous bindings
    for key, prev in last {
        if (prev != "") {
            try HotKey(prev, "Off")
        }
    }
    last := Map()
    for key, callback in bindings {
        binding := Cfg.Has(key) ? Cfg[key] : ""
        if (binding = "")
            continue
        try {
            HotKey(binding, callback)
            HotKey(binding, "On")
            last[key] := binding
        } catch Error as e {
            Log("Failed to bind hotkey " . binding . " (" . key . "): " . e.Message, "Warn")
        }
    }
}

RefreshHotkeysSummary() {
    global Cfg
    try {
        s := "F1=" . Cfg["Hotkey_ToggleMonitor"]
            . "  F2=" . Cfg["Hotkey_Reconnect"]
            . "  Min=" . Cfg["Hotkey_Minimize"]
            . "  AFK=" . Cfg["Hotkey_AntiAfk"]
            . "  Emerg=" . Cfg["Hotkey_Emergency"]
            . "  Panic=" . Cfg["Hotkey_Panic"]
        HotkeysSummary.Text := s
    } catch Error as e {
        ;
    }
}

HotkeyRebindDialog() {
    global Cfg
    dlg := Gui("+Owner" . myGui.Hwnd . " +ToolWindow", "Rebind Hotkeys")
    dlg.SetFont("s9", "Segoe UI")
    dlg.MarginX := 10
    dlg.MarginY := 10
    labels := Map(
        "Hotkey_ToggleMonitor", "Toggle monitoring:",
        "Hotkey_Reconnect",     "Manual reconnect:",
        "Hotkey_Minimize",      "Minimize Roblox:",
        "Hotkey_AntiAfk",       "Toggle Anti-AFK:",
        "Hotkey_Emergency",     "Emergency reconnect:",
        "Hotkey_Panic",         "Panic stop:"
    )
    edits := Map()
    y := 10
    for key, label in labels {
        dlg.Add("Text", "x10 y" . (y + 3) . " w160", label)
        e := dlg.Add("Hotkey", "x180 y" . y . " w180 h22", Cfg[key])
        edits[key] := e
        y += 30
    }
    okB := dlg.Add("Button", "x180 y" . (y + 10) . " w80 h26 Default", "OK")
    cancelB := dlg.Add("Button", "x270 y" . (y + 10) . " w80 h26", "Cancel")
    okB.OnEvent("Click", okClick)
    cancelB.OnEvent("Click", cancelClick)
    dlg.OnEvent("Close", cancelClick)
    dlg.Show("w380 h" . (y + 50))
    WinWaitClose("ahk_id " . dlg.Hwnd)
    return

    okClick(*) {
        for key, e in edits {
            v := e.Value
            if (v != "")
                Cfg[key] := v
        }
        SaveConfig()
        RegisterHotkeys()
        RefreshHotkeysSummary()
        dlg.Destroy()
    }
    cancelClick(*) {
        dlg.Destroy()
    }
}

; ---------- Window position / show options ----------

BuildShowOptions() {
    global Cfg
    w := Cfg.Has("WindowW") && Cfg["WindowW"] >= 400 ? Cfg["WindowW"] : 580
    h := Cfg.Has("WindowH") && Cfg["WindowH"] >= 300 ? Cfg["WindowH"] : 580
    opts := "w" . w . " h" . h
    if (Cfg.Has("RememberWindowPos") && Cfg["RememberWindowPos"]
        && Cfg.Has("WindowX") && Cfg["WindowX"] >= 0
        && Cfg.Has("WindowY") && Cfg["WindowY"] >= 0) {
        opts .= " x" . Cfg["WindowX"] . " y" . Cfg["WindowY"]
    }
    return opts
}

; ---------- Tooltips ----------

InstallTooltips() {
    ; AHK v2 tooltip-on-hover via OnMessage; light implementation:
    ; We just set window-level tooltips for selected controls using ToolTip on hover via OnEvent("MouseMove")
    ; Simpler approach: rely on the documented "ToolTip" option for built-in controls (slider).
    ; For other controls, attach via SetCapture is heavy; instead we inject tray-tip documentation.
    ; (Full-coverage tooltips reserved for V3.2.)
    try {
        ; Best-effort: store hints in StatusBar on focus.
        ProfileFilterEdit.OnEvent("Focus", (*) => StatusBar.SetText("Filter profiles by name, type, notes, link, or game ID"))
        StopAfterReconEdit.OnEvent("Focus", (*) => StatusBar.SetText("Hard cap: 0 = unlimited. Stops monitoring once cap is reached."))
        SoundVolSlider.OnEvent("Focus", (*) => StatusBar.SetText("Sound volume 0-100. Affects system master volume during playback."))
        RebindHotkeysBtn.OnEvent("Focus", (*) => StatusBar.SetText("Customize the global hotkeys used by " . APP_NAME))
        SelfTestBtn.OnEvent("Focus", (*) => StatusBar.SetText("Run quick checks: data dir, internet, Roblox install, Discord webhook"))
        RobloxStatusBtn.OnEvent("Focus", (*) => StatusBar.SetText("Ping Roblox status API to detect platform-wide outages"))
        CheckUpdatesBtn.OnEvent("Focus", (*) => StatusBar.SetText("Check the GitHub releases API for a newer version"))
    } catch Error as e {
        ;
    }
}

; ---------- Battery / power ----------

ApplyBatteryWatcher() {
    global Cfg, BatteryCheckTimer
    if (BatteryCheckTimer) {
        try SetTimer(BatteryCheckTimer, 0)
        BatteryCheckTimer := ""
    }
    if (!Cfg["PauseOnBattery"])
        return
    BatteryCheckTimer := () => BatteryCheckTick()
    SetTimer(BatteryCheckTimer, 30000)
}

BatteryCheckTick() {
    global Cfg, IsMonitoringActive
    if (!Cfg["PauseOnBattery"])
        return
    if (IsOnBattery() && IsMonitoringActive) {
        Log("On battery power - pausing monitoring", "Warn")
        StopMonitoring()
        Notify("error", APP_NAME, "Paused: system on battery power")
    }
}

IsOnBattery() {
    ; SYSTEM_POWER_STATUS struct: ACLineStatus byte: 0=offline (battery), 1=online, 255=unknown
    sps := Buffer(12, 0)
    try {
        if (!DllCall("kernel32\GetSystemPowerStatus", "Ptr", sps.Ptr))
            return false
        ac := NumGet(sps, 0, "UChar")
        return ac = 0
    } catch Error as e {
        return false
    }
}

; ---------- Profile import/export (JSON) ----------

ExportProfilesJson() {
    global Profiles
    dest := FileSelect("S", , "Export profiles", "JSON (*.json)")
    if (!dest)
        return
    if (!RegExMatch(dest, "i)\.json$"))
        dest .= ".json"
    try {
        json := "[`n"
        for i, p in Profiles {
            json .= "  {"
                . '"name":"' . EscapeJson(p["name"]) . '",'
                . '"type":"' . EscapeJson(p["type"]) . '",'
                . '"link":"' . EscapeJson(p["link"]) . '",'
                . '"gameId":"' . EscapeJson(p["gameId"]) . '",'
                . '"notes":"' . EscapeJson(p["notes"]) . '",'
                . '"fav":' . ((p.Has("fav") && p["fav"]) ? "true" : "false")
                . "}"
            if (i < Profiles.Length)
                json .= ","
            json .= "`n"
        }
        json .= "]`n"
        if (FileExist(dest))
            FileDelete(dest)
        FileAppend(json, dest)
        MsgBox("Exported " . Profiles.Length . " profile(s) to:`n" . dest, APP_NAME, 64)
    } catch Error as e {
        MsgBox("Export failed: " . e.Message, APP_NAME, 16)
    }
}

ImportProfilesJson() {
    global Profiles
    src := FileSelect(1, , "Import profiles", "JSON (*.json)")
    if (!src)
        return
    try {
        content := FileRead(src)
    } catch Error as e {
        MsgBox("Read failed: " . e.Message, APP_NAME, 16)
        return
    }
    imported := ParseProfilesJson(content)
    if (imported.Length = 0) {
        MsgBox("No profiles found in file (or unsupported format).", APP_NAME, 48)
        return
    }
    choice := MsgBox(imported.Length . " profile(s) found.`n`nYes = Replace all`nNo = Append`nCancel = Abort",
        APP_NAME, 3 + 32)
    if (choice = "Cancel")
        return
    if (choice = "Yes")
        Profiles := []
    for p in imported
        Profiles.Push(p)
    SaveProfiles()
    RefreshProfilesLV()
    RefreshProfileDropDown()
    Log("Imported " . imported.Length . " profile(s) from JSON", "Info")
}

ParseProfilesJson(text) {
    ; Minimal JSON parser tailored to our exported structure.
    ; Tolerant of whitespace; expects an array of objects with the documented fields.
    out := []
    pos := 1
    Loop {
        ; Find next '{'
        objStart := InStr(text, "{", false, pos)
        if (!objStart)
            break
        objEnd := InStr(text, "}", false, objStart)
        if (!objEnd)
            break
        chunk := SubStr(text, objStart, objEnd - objStart + 1)
        p := Map(
            "name",   ReadJsonStr(chunk, "name"),
            "type",   ReadJsonStr(chunk, "type"),
            "link",   ReadJsonStr(chunk, "link"),
            "gameId", ReadJsonStr(chunk, "gameId"),
            "notes",  ReadJsonStr(chunk, "notes"),
            "fav",    ReadJsonBool(chunk, "fav")
        )
        if (p["name"] = "")
            p["name"] := "Imported"
        if (p["type"] != "private" && p["type"] != "public")
            p["type"] := "private"
        out.Push(p)
        pos := objEnd + 1
    }
    return out
}

ReadJsonStr(chunk, key) {
    pat := '"' . key . '"\s*:\s*"((?:[^"\\]|\\.)*)"'
    if (RegExMatch(chunk, pat, &m))
        return UnescapeJson(m[1])
    return ""
}

ReadJsonBool(chunk, key) {
    pat := '"' . key . '"\s*:\s*(true|false)'
    if (RegExMatch(chunk, pat, &m))
        return m[1] = "true"
    return false
}

UnescapeJson(s) {
    s := StrReplace(s, "\n", "`n")
    s := StrReplace(s, "\r", "`r")
    s := StrReplace(s, "\t", "`t")
    s := StrReplace(s, '\"', '"')
    s := StrReplace(s, "\\", "\")
    return s
}

; ---------- Stats CSV export ----------

ExportStatsCsv() {
    global LifetimeReconnects, LifetimeCrashes, LifetimeSessions
    global SuccessfulReconnects, FailedReconnects, ReconnectAttempts, SessionStart
    dest := FileSelect("S", , "Export stats", "CSV (*.csv)")
    if (!dest)
        return
    if (!RegExMatch(dest, "i)\.csv$"))
        dest .= ".csv"
    uptimeMs := A_TickCount - SessionStart
    totalAttempts := SuccessfulReconnects + FailedReconnects
    successRate := totalAttempts > 0 ? Round(100.0 * SuccessfulReconnects / totalAttempts, 1) : 0
    csv := "metric,value`r`n"
    csv .= "session_uptime," . FormatDuration(uptimeMs) . "`r`n"
    csv .= "session_attempts," . ReconnectAttempts . "`r`n"
    csv .= "session_successful," . SuccessfulReconnects . "`r`n"
    csv .= "session_failed," . FailedReconnects . "`r`n"
    csv .= "session_success_rate_pct," . successRate . "`r`n"
    csv .= "lifetime_sessions," . LifetimeSessions . "`r`n"
    csv .= "lifetime_reconnects," . LifetimeReconnects . "`r`n"
    csv .= "lifetime_crashes," . LifetimeCrashes . "`r`n"
    try {
        if (FileExist(dest))
            FileDelete(dest)
        FileAppend(csv, dest)
        MsgBox("Stats exported to:`n" . dest, APP_NAME, 64)
    } catch Error as e {
        MsgBox("Export failed: " . e.Message, APP_NAME, 16)
    }
}

; ---------- Roblox status / self-test / update check ----------

CheckRobloxStatus(verbose) {
    try {
        http := ComObject("WinHttp.WinHttpRequest.5.1")
        http.SetTimeouts(4000, 4000, 4000, 4000)
        http.Open("GET", "https://status.roblox.com/api/v2/status.json", false)
        http.Send()
        body := http.ResponseText
        ; Look for "indicator":"none" / "minor" / "major"
        indicator := "unknown"
        if (RegExMatch(body, '"indicator"\s*:\s*"([^"]+)"', &m))
            indicator := m[1]
        desc := ""
        if (RegExMatch(body, '"description"\s*:\s*"([^"]+)"', &md))
            desc := md[1]
        msg := "Roblox status: " . indicator . (desc != "" ? "`n" . desc : "")
        Log("Roblox status: " . indicator . " (" . desc . ")", "Info")
        if (verbose)
            MsgBox(msg, APP_NAME, indicator = "none" ? 64 : 48)
        return indicator
    } catch Error as e {
        Log("Roblox status check failed: " . e.Message, "Warn")
        if (verbose)
            MsgBox("Could not reach Roblox status API.`n" . e.Message, APP_NAME, 48)
        return "unreachable"
    }
}

RunSelfTest() {
    out := "Self-test results:`n`n"
    out .= "• Data folder: " . (DirExist(DATA_DIR) ? "OK (" . DATA_DIR . ")" : "MISSING") . "`n"
    out .= "• Config file: " . (FileExist(CONFIG_FILE) ? "OK" : "not yet created") . "`n"
    out .= "• Profiles file: " . (FileExist(PROFILES_FILE) ? "OK (" . Profiles.Length . " profile(s))" : "not yet created") . "`n"
    out .= "• Internet: " . (CheckInternet() ? "OK" : "FAIL") . "`n"
    out .= "• Roblox installed: " . (FileExist(A_AppData . "\..\Local\Roblox\Versions") || FileExist("C:\Program Files (x86)\Roblox") ? "likely" : "not detected") . "`n"
    out .= "• Roblox running: " . (ProcessExist("RobloxPlayerBeta.exe") ? "yes" : "no") . "`n"
    out .= "• Roblox status API: " . CheckRobloxStatus(false) . "`n"
    out .= "• Discord webhook: " . (Cfg["DiscordEnabled"] && Cfg["DiscordWebhook"] != "" ? "configured" : "not configured") . "`n"
    out .= "• Active profile: " . (GetActiveProfile() ? GetActiveProfile()["name"] : "(none)") . "`n"
    out .= "• Anti-AFK enabled: " . (Cfg["AntiAfkEnabled"] ? "yes" : "no") . "`n"
    out .= "• On battery: " . (IsOnBattery() ? "yes" : "no") . "`n"
    MsgBox(out, APP_NAME . " - Self-test", 64)
}

CheckForUpdates(verbose) {
    global APP_VERSION, APP_REPO
    url := "https://api.github.com/repos/" . APP_REPO . "/releases/latest"
    try {
        http := ComObject("WinHttp.WinHttpRequest.5.1")
        http.SetTimeouts(4000, 4000, 4000, 4000)
        http.Open("GET", url, false)
        http.SetRequestHeader("User-Agent", "RobloxReconnect-Updater")
        http.SetRequestHeader("Accept", "application/vnd.github+json")
        http.Send()
        body := http.ResponseText
        latest := ""
        if (RegExMatch(body, '"tag_name"\s*:\s*"v?([^"]+)"', &m))
            latest := m[1]
        if (latest = "") {
            if (verbose)
                MsgBox("Could not parse latest release.", APP_NAME, 48)
            return
        }
        if (CompareVersions(latest, APP_VERSION) > 0) {
            Log("Update available: v" . latest . " (current v" . APP_VERSION . ")", "Info")
            res := MsgBox("A new version is available!`n`nLatest: v" . latest . "`nCurrent: v" . APP_VERSION
                . "`n`nOpen releases page?", APP_NAME, 4 + 32)
            if (res = "Yes")
                Run("https://github.com/" . APP_REPO . "/releases/latest")
        } else if (verbose) {
            MsgBox("You're up to date (v" . APP_VERSION . ").", APP_NAME, 64)
        }
    } catch Error as e {
        Log("Update check failed: " . e.Message, "Warn")
        if (verbose)
            MsgBox("Update check failed:`n" . e.Message, APP_NAME, 48)
    }
}

CompareVersions(a, b) {
    aP := StrSplit(a, ".")
    bP := StrSplit(b, ".")
    n := Max(aP.Length, bP.Length)
    Loop n {
        ai := aP.Length >= A_Index ? Integer(aP[A_Index]) : 0
        bi := bP.Length >= A_Index ? Integer(bP[A_Index]) : 0
        if (ai > bi)
            return 1
        if (ai < bi)
            return -1
    }
    return 0
}
