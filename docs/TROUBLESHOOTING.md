# OmniScreen Troubleshooting Guide

Common issues and their solutions when using OmniScreen.

---

### 1. Device Status Shows "Unauthorized"
* **Cause**: Your phone has not yet accepted the computer's RSA authorization key.
* **Fix**: Unlock your phone screen. Check the prompt that asks **"Allow USB debugging?"**, select the checkbox for **"Always allow from this computer"**, and press **Allow**.

---

### 2. Device Status Shows "No Phone Detected"
* **Cause**: The phone is disconnected, the cable is charge-only, or USB Debugging is turned off.
* **Fix**:
  1. Re-plug the USB data cable into a different port on your laptop.
  2. Ensure **USB Debugging** is enabled under `Settings > Developer Options`.
  3. **No USB Debugging?** Click the **`[📡 Wireless Cast (No Debugging)]`** button in the OmniScreen header and connect via **Samsung Smart View** or **Android Cast** without any developer settings!

---

### 3. Apps (Like Notesnook) Appearing in a Narrow Phone Strip with Gray Borders
* **Cause**: Android enforces portrait/fixed-aspect-ratio restrictions by default on certain apps.
* **Fix**:
  - OmniScreen automatically unlocks Android multi-window resizing globally upon session launch.
  - Simply click the **Maximize (`□`) button** on the app window's top title bar, or double-click the title bar, to expand the app into full-screen desktop mode!

---

### 4. Elements, Buttons, or Text Look Too Big or Too Small
* **Cause**: Display DPI scaling mismatch.
* **Fix**:
  - In OmniScreen, use the **UI Sizing & Density Slider** before launching Virtual Desktop:
    - **`[180 Compact]`**: Maximum screen real estate.
    - **`[200 Balanced (Default)]`**: Balanced desktop scale matching native Windows 125% laptop scaling.
    - **`[215 Comfort]`**: Larger buttons and text for touch screens.

---

### 5. Exiting & Toggling Fullscreen Mode
* Click the floating **`[🗗 Fullscreen]`** widget in the top-right corner of the screen.
* Alternatively, press **`F11`** anytime to toggle between windowed and fullscreen.
* Press **`Alt + Q`** to close the active session immediately.

---

### 6. Opening the Samsung DeX Apps / Start Menu
* When in Virtual Desktop mode, press the **Windows Key** on your physical keyboard.
* OmniScreen's low-level keyboard interceptor suppresses the Windows Start menu and directs `KEYCODE_META_LEFT` to the DeX display, opening the DeX Apps drawer.

---

### 7. Audio Playback Routing
* If sound does not route to your laptop speakers:
  1. Ensure the audio option in OmniScreen is set to **Laptop Speakers**.
  2. Verify that your laptop's master volume is unmuted.
  3. On Samsung Galaxy devices, open the notification shade and tap **Media output** to confirm the active audio target.

---

### 8. HDMI Video Capture Card (PS4 / Consoles / Chromecast / USB-C HDMI)
* Plug the console or phone's HDMI output into the USB video capture card, then insert the capture card into a USB 3.0 port.
* In OmniScreen, click **🎮 Start Console Feed** (Card 3) to view the 60 FPS feed.
* Windows Camera permissions must allow desktop applications access to camera and microphone devices (`Windows Settings > Privacy & security > Camera`).
