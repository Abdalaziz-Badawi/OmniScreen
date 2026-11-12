# OmniScreen 🚀
### Universal Virtual Display, Samsung Mobile Bridge & Console Capture

**OmniScreen** transforms your laptop into a high-performance external display and bridge for mobile devices and gaming hardware. Designed specifically for seamless multi-device workflows, low-latency streaming, and desktop integration.

---

## ✨ Features

- **📱 Native Mobile Integration (Samsung Galaxy S25 FE & Android)**:
  - Full bidirectional control with laptop keyboard, mouse, and trackpad gestures.
  - 60 FPS hardware-accelerated video stream with sub-frame display latency.
  - Native phone mirror mode (accessing all your active background apps, recent apps, and notifications).
  - Extended 1080p landscape virtual desktop canvas.

- **🛡️ Smart Windows Key Interceptor**:
  - Built-in low-level C# Windows keyboard hook (`WH_KEYBOARD_LL`).
  - Completely suppresses the Windows Start Menu and Taskbar from popping up over fullscreen sessions.
  - Automatically translates the Windows key into the Android Recent Apps / Overview (`KEYCODE_APP_SWITCH`).

- **🗗 Retractable Fullscreen Toggle Button**:
  - Discreet, floating corner toggle button pinned to the screen.
  - Idle state: Retracts to 25% opacity so it never obstructs apps, games, or videos.
  - One click toggles between Fullscreen and Windowed mode.
  - Freely draggable anywhere on the screen if you wish to reposition it.
  - Hardware shortcut: Press **`F11`** or **`Alt + F`** anytime.

- **🔊 Flexible Audio Routing**:
  - **Laptop Speakers (Default)**: Routes digital audio through your laptop speakers with low-latency buffering.
  - **Phone Speakers**: Leaves audio playing directly through the phone's built-in stereo speakers.
  - **Simultaneous (Both)**: Dual-stream duplicate audio to both laptop and phone speakers.
  - On-the-fly switching directly from the phone's **Media Output** panel or the laptop hover bar.

- **🎮 Console & Chromecast Display Engine**:
  - Direct low-latency pass-through for PlayStation 4, Nintendo Switch, Xbox, or Chromecast.
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
└── app/                         # Core Application Modules
    ├── Main.ps1                 # Master WPF UI & orchestrator
    ├── DeviceEngine.ps1         # Hardware detection & Samsung model decoder
    ├── DisplayManager.ps1       # Scrcpy & capture pipeline controller
    ├── KeyboardHook.cs          # Low-level Windows keyboard interceptor (C#)
    ├── FullscreenToggle.ps1     # Retractable floating fullscreen toggle button
    └── ConsoleViewer.html       # Dedicated gaming console & Chromecast feed
```

---

## ⚡ Quick Start

1. **Connect your Phone via USB**:
   - Ensure **USB Debugging** is enabled on your phone (`Settings > Developer Options > USB Debugging`).
2. **Launch OmniScreen**:
   - Run `OmniScreen.vbs` or double-click the **OmniScreen** desktop shortcut.
3. **Select Your Mode**:
   - Choose **Phone Workspace & Live Apps** or **Extended 1080p Virtual Desktop**.
   - Select your preferred audio destination (Laptop, Phone, or Both).
   - Click **▶ LAUNCH DISPLAY SESSION**.

---

## ⌨️ Keyboard Shortcuts Reference

| Shortcut | Action |
| :--- | :--- |
| **Hover Top Edge** | Slides down the Floating Capsule Toolbar |
| **Windows Key** | Opens Android Recent Apps / Overview (No Windows Start Menu interference) |
| **F11 / Alt + F** | Toggle Fullscreen / Windowed Mode (reveals title bar & `[X]` button) |
| **Alt + Q** | Instantly exit the session and return to Windows |
| **Alt + O** | Toggle physical phone screen on/off (Power Saver mode) |
| **Right-Click** | Android Back Button |

---

## 🛠️ Requirements & Tech Stack

- **OS**: Windows 10 / 11 (64-bit)
- **Engine**: [scrcpy](https://github.com/Genymobile/scrcpy) v5.0+ & Android Debug Bridge (ADB)
- **Framework**: .NET Framework 4.8 / Windows Presentation Foundation (WPF) & PowerShell 5.1+
- **Capture Hardware (Optional)**: Standard UVC USB 3.0 HDMI Capture Card for PS4/Chromecast

---

## 👤 Author

Developed by **Abdalaziz Badawi** ([@devBadawi](https://github.com/devBadawi)) / ([@Abdalaziz-Badawi](https://github.com/Abdalaziz-Badawi))
