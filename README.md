# 🎮 Roblox Auto-Reconnect Tool

<div align="center">

![Roblox](https://img.shields.io/badge/Roblox-00A2FF?style=for-the-badge&logo=roblox&logoColor=white)
![AutoHotkey](https://img.shields.io/badge/AutoHotkey-334455?style=for-the-badge&logo=autohotkey&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-0078D4?style=for-the-badge&logo=windows&logoColor=white)

**Automated Roblox connection management tool with GUI interface**

> 🎉 **V3.0 is here!** A complete rebuild with tabbed UI, multi-profile servers,
> tray icon, anti-AFK, Discord webhooks, scheduling and 70+ features.
> See [FEATURES.md](./FEATURES.md) for the full 200-feature roadmap.
>
> **Script:** `RobloxReconnectV3.0.Ahk` (V2 is kept as `RobloxReconnectV2.0.Ahk`)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![AutoHotkey v2](https://img.shields.io/badge/AutoHotkey-v2.0-blue.svg)](https://www.autohotkey.com/)
[![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey.svg)](https://www.microsoft.com/en-us/windows)

</div>

---

## ✨ Features

### 🔄 **Auto Reconnection**
- Automatically detects when Roblox disconnects
- Instantly reconnects using your VIP server link
- Handles connection errors and timeouts

### ⏰ **Scheduled Rejoin**
- Auto-rejoin every 1-24 hours (configurable)
- Prevents long AFK timeouts
- Maintains continuous server presence

### 🔽 **GPU Saver (Minimize Roblox)**
- Optional: minimize the Roblox window automatically after joining
- Reduces GPU load while idling in a server
- Toggle from the GUI at any time

### 🌐 **Browser Management**
- Automatically closes web browsers after successful reconnection
- Supports all major browsers (Chrome, Firefox, Edge, Opera, Brave, etc.)
- Helps free up system resources

### 🎛️ **User-Friendly GUI**
- Clean, intuitive interface
- Real-time status monitoring
- Comprehensive logging system
- Customizable settings

---

## 📋 Requirements

- **Windows 7/8/10/11**
- **AutoHotkey v2.0+** ([Download here](https://www.autohotkey.com/))
- **Roblox** installed on your system

---

## 🚀 Installation

1. **Download AutoHotkey v2**
   ```
   https://www.autohotkey.com/download/
   ```

2. **Clone this repository**
   ```bash
   git clone https://github.com/yourusername/roblox-auto-reconnect.git
   cd roblox-auto-reconnect
   ```

3. **Run the script**
   - Double-click `RobloxAutoReconnect.ahk`
   - Or right-click and select "Compile Script" to create an executable

---

## 🎯 Usage

### Getting Started
1. **Launch the tool** - Run the `.ahk` file or compiled `.exe`
2. **Enter VIP Server Link** - Paste your Roblox VIP server link
3. **Test Connection** - Click "Test" to verify the link works
4. **Configure Settings** - Set your preferred monitoring interval and auto-rejoin schedule
5. **Start Monitoring** - Click "Start Monitoring" to begin

### Configuration Options

| Setting | Description | Default |
|---------|-------------|---------|
| **VIP Server Link** | Your Roblox VIP server URL | - |
| **Check Interval** | How often to check connection (seconds) | 5 |
| **Auto Rejoin** | Scheduled rejoin interval (hours) | 1 |
| **Minimize Roblox** | Minimize Roblox after opening (GPU saver) | - |
| **Auto Monitoring** | Start monitoring automatically | - |

---

## ⌨️ Hotkeys

| Key | Function |
|-----|----------|
| `F1` | Toggle monitoring on/off |
| `F2` | Manual reconnect |

---

## 📊 Screenshots

### Main Interface
```
┌─────────────────────────────────────────┐
│ 🎮 Roblox Auto-Reconnect Tool          │
├─────────────────────────────────────────┤
│ VIP Server Link: [________________Test] │
│ Monitoring Status: ✅ Enabled           │
│ ☑ Enable Auto Monitoring               │
│ Auto Rejoin every: [1▼] hours ☑ Enable │
│ Check every: [5] seconds                │
│ [Start] [Stop] [Reconnect] [Exit]       │
│ ┌─────────────────────────────────────┐ │
│ │ [12:34:56] Started monitoring...    │ │
│ │ [12:35:01] ✅ Roblox opened        │ │
│ │ [12:35:09] 🎮 Successfully joined  │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

---

## 🔧 Advanced Configuration

### Supported Browsers
The tool automatically closes these browsers after reconnection:
- **Google Chrome** (`chrome.exe`)
- **Mozilla Firefox** (`firefox.exe`)
- **Microsoft Edge** (`msedge.exe`)
- **Opera** (`opera.exe`)
- **Brave Browser** (`brave.exe`)
- **Vivaldi** (`vivaldi.exe`)
- **Internet Explorer** (`iexplore.exe`)

### Customizing Check Intervals
```autohotkey
; Modify these values in the script
CHECK_INTERVAL := 5000    ; 5 seconds (in milliseconds)
RECONNECT_DELAY := 3000   ; 3 seconds delay before reconnect
```

---

## 🐛 Troubleshooting

### Common Issues

**❌ Script won't start**
- Ensure you have AutoHotkey v2.0+ installed
- Right-click the script and "Run as Administrator"

**❌ Test connection fails**
- Verify your VIP server link is correct
- Check if Roblox is properly installed
- Ensure link format: `roblox://placeId=123456&linkCode=abcdef`

**❌ Auto-rejoin not triggering**
- Check that "Enable Auto Rejoin" is checked
- Verify the hour interval is set correctly
- Monitor the log for scheduled rejoin messages

### Getting Help
If you encounter issues:
1. Check the log output in the GUI
2. Run as Administrator
3. Disable antivirus temporarily for testing
4. [Open an issue](https://github.com/yourusername/roblox-auto-reconnect/issues)

---

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/AmazingFeature`)
3. **Commit** your changes (`git commit -m 'Add some AmazingFeature'`)
4. **Push** to the branch (`git push origin feature/AmazingFeature`)
5. **Open** a Pull Request

### Development Guidelines
- Follow AutoHotkey v2 syntax
- Add comments for complex logic
- Test thoroughly before submitting
- Update documentation as needed

---

## 📝 Changelog

### v1.0.0 (2024-09-08)
- ✨ Initial release
- 🔄 Auto-reconnection functionality
- ⏰ Scheduled auto-rejoin system
- 🖥️ Borderless fullscreen support
- 🌐 Automatic browser cleanup
- 🎛️ Full GUI interface with logging

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2024 Roblox Auto-Reconnect Tool

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction...
```

---

## ⚠️ Disclaimer

This tool is for educational and convenience purposes only. Use at your own risk and ensure compliance with Roblox's Terms of Service. The developers are not responsible for any account actions taken by Roblox.

---

## 🌟 Support

If this tool helped you, consider:
- ⭐ **Star** this repository
- 🐛 **Report** any bugs you find
- 💡 **Suggest** new features
- 🤝 **Share** with friends

---

<div align="center">

**Made with ❤️ for the Roblox community**

[Report Bug](https://github.com/0Xd01x/roblox-auto-reconnect/issues) • [Request Feature](https://github.com/0Xd01x/roblox-auto-reconnect/issues) • [Discord](https://discord.gg/gRPG3WkWVv)

</div>
