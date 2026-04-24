# Roblox Auto-Reconnect V3 — Feature Roadmap (200)

Legend: ✅ Implemented in V3 · 🟡 Partial / behind a flag · 🚧 Planned · 💡 Nice-to-have

## Connection & Monitoring
1. ✅ Auto-reconnect on Roblox process exit
2. ✅ Auto-reconnect on Roblox error dialogs (disconnected / lost connection / error codes)
3. ✅ Auto-reconnect on window-title disconnect patterns
4. ✅ Configurable check interval (seconds)
5. ✅ Scheduled auto-rejoin every N hours + M minutes
6. ✅ Max reconnect attempts cap (0 = unlimited)
7. ✅ Cooldown between reconnect attempts
8. ✅ Exponential backoff on repeated failures
9. ✅ Randomized jitter on reconnect
10. ✅ Internet connectivity pre-check (skip when offline, retry in 15s)
11. ✅ Manual "Reconnect Now" button
12. ✅ Emergency reconnect hotkey (Ctrl+Shift+R)
13. ✅ Panic stop (stops all timers + anti-afk)
14. ✅ Session uptime tracking
15. ✅ Lifetime reconnect counter
16. ✅ Lifetime crash counter
17. 🚧 Ping / latency pre-check
18. 🚧 DNS resolution check before reconnect
19. 🚧 Roblox status API check (https://status.roblox.com)
20. 🚧 Smart rate-limit avoidance (detect 429-like patterns)

## Server Profiles
21. ✅ Multi-profile manager (add / edit / duplicate / delete)
22. ✅ Private/VIP link profile type
23. ✅ Public game ID profile type
24. ✅ Per-profile notes
25. ✅ VIP link validation (`https://roblox.com/` or `roblox://`)
26. ✅ Game ID validation (digits only)
27. ✅ Profile ListView with columns
28. ✅ Set active profile from list
29. ✅ Test profile (launches once)
30. ✅ Copy active profile target to clipboard
31. ✅ Open active profile in browser
32. ✅ Pick random profile (roulette)
33. ✅ Persist profiles to INI
34. 🚧 Rotate through profiles on each reconnect
35. 🚧 Import profiles from text file
36. 🚧 Export profiles
37. 🚧 Tag/category system per profile
38. 🚧 Favorite/star profile flag
39. 🚧 Profile search/filter
40. 🚧 Recent servers history

## GUI & UX
41. ✅ Tabbed interface (9 tabs)
42. ✅ Resizable main window
43. ✅ Bottom status bar
44. ✅ Colour-coded status text
45. ✅ Always-on-top GUI toggle
46. ✅ Minimize to tray
47. ✅ Start minimized option
48. ✅ Inline help text / hints
49. 🟡 Rich icons (uses emoji; planned real icon set)
50. 🚧 Dark mode theme
51. 🚧 Light mode theme
52. 🚧 Follow system theme
53. 🚧 Custom accent colour
54. 🚧 High-contrast accessibility mode
55. 🚧 Configurable font size
56. 🚧 Compact/minimal mode
57. 🚧 Remember window size/position
58. 🚧 Collapsible sections
59. 🚧 Onboarding wizard for first run
60. 🚧 Localization (EN/ES/FR/DE/JA/KR/PT/RU)

## Tray
61. ✅ Tray icon with custom tooltip
62. ✅ Custom tray context menu (show / start / stop / reconnect / minimize Roblox / focus / exit)
63. ✅ Tray balloon notifications
64. 🟡 Status colour on tray icon (tooltip updates; icon swap planned)
65. 🚧 Dynamic tray menu (recent profiles submenu)
66. 🚧 Tray right-click "pause for N minutes"

## Hotkeys
67. ✅ F1 toggle monitoring
68. ✅ F2 manual reconnect
69. ✅ F3 minimize Roblox
70. ✅ F4 toggle anti-AFK
71. ✅ Ctrl+Shift+R emergency reconnect
72. ✅ Ctrl+Shift+Q panic stop
73. 🚧 Fully user-configurable hotkey bindings
74. 🚧 Hotkey conflict detection
75. 🚧 Quick-switch profile hotkey

## Window Management
76. ✅ Minimize Roblox after joining (GPU saver)
77. ✅ Focus Roblox button
78. ✅ Force-kill Roblox button
79. ✅ Always-on-top for Roblox windows
80. ✅ Process priority (Low/Normal/High)
81. 🚧 CPU affinity selection
82. 🚧 GPU preference (high-perf / low-power via Windows graphics settings)
83. 🚧 Force borderless
84. 🚧 Force windowed
85. 🚧 Multi-monitor target picker
86. 🚧 Set Roblox window position/size
87. 🚧 Live memory/CPU usage display
88. 🚧 Window thumbnail preview

## Browser Management
89. ✅ Close browsers after successful join (optional)
90. ✅ Editable browser executable list
91. ✅ "Close Browsers Now" manual button
92. 🚧 Whitelist mode (don't close if > N tabs)
93. 🚧 Close only the launcher-triggered browser window

## Anti-AFK
94. ✅ Mouse jiggle method
95. ✅ Key press method (configurable key)
96. ✅ Configurable interval + jitter
97. ✅ Focus gating (only when Roblox active)
98. ✅ Manual "test once" button
99. 🚧 Custom key sequences / macros
100. 🚧 Anti-AFK profile presets (idle-farm / grinder / chatter)
101. 🚧 Randomized jiggle patterns
102. 🚧 Pause during reconnect
103. 🚧 Record/replay idle routine

## Notifications & Alerts
104. ✅ Tray balloon notifications
105. ✅ Per-event notify toggles (connect / disconnect / error)
106. ✅ Sound file alerts (.wav/.mp3)
107. ✅ Discord webhook alerts
108. ✅ Test tray / test Discord buttons
109. 🚧 Volume slider for sound alerts
110. 🚧 Telegram bot integration
111. 🚧 Email alerts on prolonged disconnect
112. 🚧 Discord rich embeds with stats
113. 🚧 Push notifications via ntfy.sh

## Scheduling & Lifecycle
114. ✅ Scheduled auto-rejoin (hours + minutes)
115. ✅ Delayed start timer on launch
116. ✅ Stop-at-time (HH:MM)
117. ✅ Start monitoring on launch toggle
118. ✅ Prevent system sleep while monitoring
119. ✅ Windows auto-start via `Run` registry key
120. 🚧 Weekly schedule (day-of-week masks)
121. 🚧 Cron-style scheduling
122. 🚧 Stop after N reconnects
123. 🚧 Pause on battery
124. 🚧 Wake-from-sleep on scheduled rejoin
125. 🚧 Holiday / DND mode

## Security & Validation
126. ✅ VIP link format validation
127. ✅ Game ID format validation
128. ✅ Reject arbitrary URLs (no shell-exec of untrusted strings)
129. 🚧 Mask VIP link in UI (click-to-reveal)
130. 🚧 Hide link in logs
131. 🚧 PIN-lock sensitive settings
132. 🚧 Warn on suspicious URL patterns

## Logging
133. ✅ Persistent rotating log file (512 KB rotation)
134. ✅ In-GUI log tail view
135. ✅ Log level filter (Debug/Info/Warn/Error)
136. ✅ Clear log button
137. ✅ Copy log to clipboard
138. ✅ Export log to text file
139. ✅ Open log file externally
140. ✅ Timestamped entries
141. ✅ Log-level rank filtering
142. 🚧 In-log search (Ctrl+F)
143. 🚧 Colour-coded log lines
144. 🚧 Structured (JSON) log option
145. 🚧 Remote log forwarding

## Stats & Analytics
146. ✅ Session uptime
147. ✅ Session reconnect count
148. ✅ Lifetime reconnects / crashes / sessions
149. ✅ Average reconnects per session
150. ✅ Reset lifetime stats
151. ✅ Active profile summary
152. 🚧 Per-day bar chart
153. 🚧 Longest uninterrupted uptime
154. 🚧 Time-to-reconnect distribution
155. 🚧 Success rate %
156. 🚧 Weekly digest (Discord)
157. 🚧 CSV export

## Configuration
158. ✅ INI config file
159. ✅ Separate profiles INI
160. ✅ Stats INI
161. ✅ Save / reload from disk
162. ✅ Export / import config
163. ✅ Reset to defaults (preserves profiles)
164. ✅ Open data folder button
165. 🚧 JSON config option
166. 🚧 Config backup on each save
167. 🚧 Portable mode (no registry, no %APPDATA%)
168. 🚧 Per-profile config overrides

## Diagnostics
169. ✅ Internet connectivity check
170. 🚧 Built-in self-test button
171. 🚧 Network latency graph
172. 🚧 Packet-loss indicator
173. 🚧 DNS test tool
174. 🚧 Roblox API status ping
175. 🚧 Export diagnostic bundle (.zip)

## Power User / Advanced
176. ✅ Prevent sleep (SetThreadExecutionState)
177. ✅ Process priority setter
178. 🚧 Multi-instance Roblox support
179. 🚧 Account switcher (login cookie swap)
180. 🚧 Bloxstrap / Sober / Vinegar integration
181. 🚧 Roblox log parser (FPS, ping, placeId)
182. 🚧 Auto-clear Roblox log cache
183. 🚧 Crash dump collection
184. 🚧 Opt-in anonymized telemetry

## Remote Control / Integrations
185. 🚧 Local HTTP dashboard
186. 🚧 REST API on localhost
187. 🚧 Discord bot slash-commands
188. 🚧 Mobile companion app
189. 🚧 QR code for profile sharing
190. 🚧 OBS scene switch on events
191. 🚧 Home Assistant webhook

## Misc / Nice-to-Have
192. ✅ About dialog
193. ✅ Data folder shortcut
194. ✅ In-GUI "Go To Profiles" jump button
195. 🚧 Changelog viewer
196. 🚧 Auto-update checker (GitHub releases)
197. 🚧 One-click update
198. 🚧 Birthday / seasonal easter eggs
199. 🚧 Tooltip help on every control
200. 🚧 Printable cheatsheet PDF

---

## Summary

- **~70** features fully implemented in V3.0
- **~130** planned / nice-to-have on the roadmap
- File layout:
  - `RobloxReconnectV3.0.Ahk` — main script
  - `RobloxReconnect-Data/config.ini` — user config
  - `RobloxReconnect-Data/profiles.ini` — saved server profiles
  - `RobloxReconnect-Data/stats.ini` — lifetime counters
  - `RobloxReconnect-Data/app.log` — rotating activity log
