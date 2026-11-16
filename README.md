# OmniScreen 🚀
### Universal Virtual Display, Samsung Mobile Bridge & Console Capture

**OmniScreen** transforms your Windows laptop or PC into a high-performance external display, multi-device bridge, and standalone virtual desktop. Designed for ultra-low-latency streaming, Samsung DeX integration, multi-device Android workflows, and console gaming.

---

## ✨ Features

- **🖥️ Standalone Virtual Screen & Auto-Connecting DeX**:
  - Independent 1920×1080 landscape virtual display that runs directly on your PC **even without a phone connected**.
  - Built-in background auto-connect daemon: plug in your Samsung Galaxy phone via USB anytime, and **Samsung DeX automatically launches** right onto this screen!
  - Graceful unplug handling: disconnecting the phone cleanly returns to the standalone virtual screen canvas rather than closing.
  - Multi-source options inside the screen: switch between DeX, HDMI capture, and secondary PC web workspaces.

- **📡 Wireless Smart View & Cast (Zero USB Debugging Required)**:
  - 1-click launch for **Samsung Smart View**, **Android Cast / Miracast**, and **Microsoft Phone Link**.
  - Works with any Android phone (Samsung, Pixel, Xiaomi, Motorola, etc.) with **zero developer options, zero cables, and zero USB debugging**.

- **📱 Universal Android Integration (Wired 60 FPS)**:
  - Full bidirectional control with laptop keyboard, mouse, and trackpad gestures.
  - 60 FPS hardware-accelerated video stream with sub-frame latency via `scrcpy`.
  - Universal device parser: auto-detects and targets any connected Android phone regardless of USB hub port configuration.
  - Smart DeX vs. Mirroring detection: auto-selects Samsung DeX desktop mode for Galaxy S/Z/Note devices or full Phone Workspace mirroring for other phones.

- **📐 Dynamic UI Density Scaling (200 DPI Balanced Sweet Spot)**:
  - Eliminates bloated mobile layouts (where bottom navigation bars consumed ~45% of the screen) while keeping DeX buttons, taskbar, and text crisp and comfortable.
  - Interactive **160–230 DPI slider** with 1-click quick presets:
    - **`[180 Compact]`**: Maximum screen real estate.
    - **`[200 Balanced (Default)]`**: The recommended sweet spot matching 125% laptop scale.
    - **`[215 Comfort]`**: Larger buttons and text for touch screens.

- **🔓 Auto-Enforced Multi-Window & Freeform Resizability**:
  - Automatically unlocks Android developer multi-window flags on session start.
  - Forces portrait-locked and fixed-aspect-ratio apps (like **Notesnook**) to freely expand and maximize into full-screen desktop mode without gray side borders.

- **🛡️ Smart Windows Key Interceptor**:
  - Built-in low-level C# Windows keyboard hook (`WH_KEYBOARD_LL`).
  - Suppresses the Windows Start Menu from popping over fullscreen sessions.
  - Maps the physical Windows key directly to the **Samsung DeX Apps / Start Menu** (`KEYCODE_META_LEFT`) in desktop mode, or **Home** in mirror mode.

- **🗗 Retractable Fullscreen Toggle Widget**:
  - Discreet, floating corner widget `[🗗 Fullscreen] [F11]` pinned to the top-right corner.
  - Uses Win32 `WS_EX_TOPMOST` and `WS_EX_NOACTIVATE` so clicking never steals focus from your active session.
  - Idle state: Retracts to subtle opacity so it never obstructs games or apps.
  - Freely draggable anywhere on screen. Hotkey: **`F11`**.

- **🔊 Flexible Audio Routing**:
  - **Laptop Speakers (Default)**: Routes digital audio to laptop speakers with low-latency buffering.
  - **Phone Speakers**: Leaves audio playing directly through the phone's stereo speakers.
  - **Simultaneous (Both)**: Dual-stream duplicate audio to both laptop and phone.

- **🎮 Console, Chromecast & USB-C HDMI Display Engine**:
  - Direct low-latency DirectShow pass-through for PlayStation 4, Nintendo Switch, Xbox, Chromecast, or USB-C HDMI phone output.
  - Plug-and-play with any standard USB 3.0 HDMI Video Capture Card (UVC).

---

## 📂 Project Architecture

```
OmniScreen/
│
├── OmniScreen.vbs               # Silent zero-console Windows launcher
├── README.md                    # Project documentation
├── .gitignore                   # Git ignore specifications
│
├── docs/                        # Detailed Guides
│   ├── INSTALLATION.md          # Step-by-step setup guide
│   └── TROUBLESHOOTING.md       # Problem resolution & tips
│
└── app/                         # Core Application Modules
    ├── Main.ps1                 # Master WPF dashboard & orchestrator
    ├── DisplayManager.ps1       # Scrcpy & virtual display session controller
    ├── VirtualScreen.ps1        # Standalone virtual screen & DeX auto-connect
    ├── DeviceEngine.ps1         # Universal Android & capture hardware discovery
    ├── FullscreenToggle.ps1     # Retractable floating fullscreen pill widget
    ├── KeyboardHook.cs          # Low-level Windows keyboard interceptor (C#)
    └── ConsoleViewer.html       # Dedicated gaming console & Chromecast feed
```

---

## ⚡ Quick Start

### Option A: Wired USB (High Performance 60 FPS)
1. Enable **USB Debugging** on your phone (`Settings > Developer Options > USB Debugging`).
2. Connect your phone to your PC via a USB data cable.
3. Tap **"Always allow from this computer"** when prompted on your phone screen.
4. Launch OmniScreen (`OmniScreen.vbs` or run `app/Main.ps1`).
5. Choose **Phone Workspace** or **Virtual Desktop** and click **Start**.

### Option B: Wireless Smart View / Cast (Zero USB Debugging Required)
1. Click **`[📡 Wireless Cast (No Debugging)]`** in OmniScreen's header.
2. Swipe down your phone's quick settings tray and tap **Smart View** (Samsung) or **Cast** (Pixel/Xiaomi/Motorola).
3. Select your PC to mirror your screen or boot wireless Samsung DeX immediately.

### Option C: Standalone Virtual Desktop (No Phone Needed)
1. Click **`🖥️ Start Virtual Desktop`** anytime.
2. An independent 1080p virtual display opens on your PC.
3. Plug in your Samsung phone at any point to automatically stream Samsung DeX onto the screen!

---

## ⌨️ Keyboard Shortcuts Reference

| Shortcut | Action |
| :--- | :--- |
| **F11** | Toggle Fullscreen / Windowed Mode |
| **Floating [🗗 Fullscreen]** | Click floating corner widget to toggle Fullscreen / Windowed |
| **Windows Key** | Opens Samsung DeX Apps / Start Menu (Desktop mode) or Home (Mirror mode) |
| **Alt + Q** | Instantly exit the active display session and return to Windows |
| **Alt + O** | Toggle physical phone screen on/off (Power Saver mode) |
| **Right-Click** | Android Back Button |

---

## 🛠️ Requirements & Tech Stack

- **OS**: Windows 10 / 11 (64-bit)
- **Engine**: [scrcpy](https://github.com/Genymobile/scrcpy) v5.0+ & Android Debug Bridge (ADB)
- **Framework**: .NET Framework 4.8 / Windows Presentation Foundation (WPF) & PowerShell 5.1+
- **Capture Hardware (Optional)**: Standard UVC USB 3.0 HDMI Capture Card for PS4/Switch/Chromecast

---

## 👤 Author

Developed by **Abdalaziz Badawi** ([@devBadawi](https://github.com/devBadawi)) / ([@Abdalaziz-Badawi](https://github.com/Abdalaziz-Badawi))  
*Repository*: [github.com/Abdalaziz-Badawi/OmniScreen](https://github.com/Abdalaziz-Badawi/OmniScreen)  
*Contact*: [dev.badawi@gmail.com](mailto:dev.badawi@gmail.com)
