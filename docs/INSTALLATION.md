# OmniScreen Installation & Setup Guide

This guide details the prerequisites and steps to install and run OmniScreen on a Windows system.

---

## 1. Prerequisites

### A. Windows Dependencies
* Windows 10 or Windows 11 (64-bit)
* PowerShell 5.1 or newer (pre-installed on Windows)
* .NET Framework 4.8 or newer (pre-installed on Windows)

### B. Required Tools
* **scrcpy (v2.0 or newer)**:
  Install via Windows Package Manager:
  ```powershell
  winget install Genymobile.scrcpy
  ```
* **Android Debug Bridge (ADB)**:
  Included automatically with `scrcpy` or available via Android SDK Platform-Tools.

* **Samsung Android USB Driver**:
  Required for reliable USB communication with Galaxy devices:
  ```powershell
  winget install Samsung.SamsungUSBdriver
  ```

---

## 2. Phone Configuration (One-time Setup)

1. Open your device's **Settings**.
2. Navigate to **About phone** > **Software information**.
3. Tap **Build number** seven consecutive times until developer mode activates.
4. Return to **Settings** > **Developer options**.
5. Enable **USB debugging**.
6. Connect the phone to the laptop via a USB cable.
7. When prompted with **"Allow USB debugging?"**, check **"Always allow from this computer"** and tap **Allow**.

---

## 3. Launching OmniScreen

1. Double-click the **OmniScreen** shortcut on your Desktop, or run `OmniScreen.vbs` located in the root project folder.
2. The dashboard will automatically detect your phone model and connection status.
3. Choose your display mode and audio destination, then select **Launch Display Session**.
