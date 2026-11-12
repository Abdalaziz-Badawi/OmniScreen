# OmniScreen Troubleshooting Guide

Common issues and their solutions when using OmniScreen.

---

### 1. Device Status Shows "Unauthorized"
* **Cause**: Your phone has not yet accepted the computer's RSA key.
* **Fix**: Unlock your phone screen. Check the prompt that asks **"Allow USB debugging?"**, select the checkbox for **"Always allow from this computer"**, and press **Allow**.

---

### 2. Device Status Shows "No Phone Connected"
* **Cause**: USB cable is loose, set to charge-only, or USB debugging was toggled off.
* **Fix**:
  1. Re-plug the USB cable into a different USB port on your laptop.
  2. Ensure USB debugging is toggled on under `Settings > Developer options`.
  3. Ensure the Samsung USB Mobile Driver is installed.

---

### 3. Exiting Fullscreen Mode
* Move your mouse to the top center edge of the display to reveal the slide-down floating toolbar and click **Windowed**.
* Alternatively, press **`F11`** or **`Alt + F`** to toggle between windowed and fullscreen.
* Press **`Alt + Q`** to close the session immediately.

---

### 4. Audio Playback Issues
* If sound does not route to your laptop speakers:
  1. Ensure the audio output option in OmniScreen is set to **Laptop Speakers**.
  2. Verify that your laptop's master volume is not muted.
  3. On Samsung Galaxy devices, open the notification shade and tap **Media output** to confirm the active audio target.

---

### 5. HDMI Video Capture Card (PS4 / Consoles / Chromecast)
* Plug the console's HDMI output into the USB video capture card, then insert the capture card into a USB 3.0 port.
* In OmniScreen, select **Console & Chromecast Display** and launch the session.
* Windows Camera permissions must allow desktop applications access to camera and microphone devices (`Windows Settings > Privacy & security > Camera`).
