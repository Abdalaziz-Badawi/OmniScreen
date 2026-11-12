using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

namespace OmniScreen {
    public class KeyboardHook {
        private const int WH_KEYBOARD_LL = 13;
        private const int WM_KEYDOWN = 0x0100;
        private const int WM_KEYUP = 0x0101;
        private const int WM_SYSKEYDOWN = 0x0104;
        private const int WM_SYSKEYUP = 0x0105;

        private const int VK_LWIN = 0x5B;
        private const int VK_RWIN = 0x5C;
        private const byte VK_F11 = 0x7A;

        public delegate IntPtr LowLevelKeyboardProc(int nCode, IntPtr wParam, IntPtr lParam);
        private static LowLevelKeyboardProc _proc = HookCallback;
        private static IntPtr _hookID = IntPtr.Zero;

        public static bool IsEnabled = false;
        public static int TargetProcessId = 0;
        public static string AdbPath = "";
        public static int KeyCode = 117; // 117 = KEYCODE_META_LEFT (DeX Start/Apps Menu), 3 = KEYCODE_HOME
        public static string DisplayId = ""; // Target display ID (e.g. for DeX virtual desktop)
        public static Action OnWindowsKeyPressed;

        public static void Install(int targetPid, string adb, int keyCode = 117, string displayId = "") {
            TargetProcessId = targetPid;
            AdbPath = adb;
            KeyCode = keyCode;
            DisplayId = displayId ?? "";

            if (_hookID == IntPtr.Zero) {
                using (Process curProcess = Process.GetCurrentProcess())
                using (ProcessModule curModule = curProcess.MainModule) {
                    _hookID = SetWindowsHookEx(WH_KEYBOARD_LL, _proc, GetModuleHandle(curModule.ModuleName), 0);
                }
                IsEnabled = (_hookID != IntPtr.Zero);
            } else {
                IsEnabled = true;
            }
        }

        public static void SetTargetDisplay(string displayId, int keyCode = 117) {
            DisplayId = displayId ?? "";
            KeyCode = keyCode;
        }

        public static void Uninstall() {
            if (_hookID != IntPtr.Zero) {
                UnhookWindowsHookEx(_hookID);
                _hookID = IntPtr.Zero;
            }
            IsEnabled = false;
        }

        private static bool IsOmniScreenActive() {
            IntPtr fg = GetForegroundWindow();
            if (fg == IntPtr.Zero) return false;

            uint fgPid;
            GetWindowThreadProcessId(fg, out fgPid);
            if (TargetProcessId > 0 && fgPid == (uint)TargetProcessId) return true;

            StringBuilder sb = new StringBuilder(256);
            GetWindowText(fg, sb, sb.Capacity);
            string title = sb.ToString();
            return title.StartsWith("OmniScreen");
        }

        private static IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam) {
            if (nCode >= 0 && IsEnabled) {
                int vkCode = Marshal.ReadInt32(lParam);
                if (vkCode == VK_LWIN || vkCode == VK_RWIN) {
                    // Only intercept if OmniScreen or its scrcpy window is the active foreground window
                    if (IsOmniScreenActive()) {
                        int msg = wParam.ToInt32();
                        if (msg == WM_KEYDOWN || msg == WM_SYSKEYDOWN) {
                            // Trigger ADB asynchronously on ThreadPool so hook NEVER blocks
                            if (!string.IsNullOrEmpty(AdbPath)) {
                                int codeToSend = KeyCode;
                                string adbExe = AdbPath;
                                string dispId = DisplayId;
                                ThreadPool.QueueUserWorkItem(_ => {
                                    try {
                                        string cmdArgs = string.IsNullOrEmpty(dispId)
                                            ? ("shell input keyevent " + codeToSend)
                                            : ("shell input -d " + dispId + " keyevent " + codeToSend);

                                        ProcessStartInfo psi = new ProcessStartInfo {
                                            FileName = adbExe,
                                            Arguments = cmdArgs,
                                            CreateNoWindow = true,
                                            UseShellExecute = false,
                                            WindowStyle = ProcessWindowStyle.Hidden
                                        };
                                        using (Process p = Process.Start(psi)) {
                                            if (p != null) p.WaitForExit(1000);
                                        }
                                    } catch { }
                                });
                            }

                            if (OnWindowsKeyPressed != null) {
                                ThreadPool.QueueUserWorkItem(_ => {
                                    try { OnWindowsKeyPressed.Invoke(); } catch { }
                                });
                            }
                        }
                        // Return 1 to completely suppress the Windows Start Menu!
                        return (IntPtr)1;
                    }
                }
            }
            return CallNextHookEx(_hookID, nCode, wParam, lParam);
        }

        // --- Window Helpers & Fullscreen Toggle ---

        private static readonly IntPtr HWND_TOPMOST = new IntPtr(-1);
        private const uint SWP_NOSIZE = 0x0001;
        private const uint SWP_NOMOVE = 0x0002;
        private const uint SWP_NOACTIVATE = 0x0010;
        private const uint SWP_SHOWWINDOW = 0x0040;

        private const int GWL_EXSTYLE = -20;
        private const int WS_EX_NOACTIVATE = 0x08000000;
        private const int WS_EX_TOPMOST = 0x00000008;
        private const int WS_EX_TOOLWINDOW = 0x00000080;

        public static void MakeTopmostAndNoActivate(IntPtr hWnd) {
            if (hWnd == IntPtr.Zero) return;
            try {
                int exStyle = GetWindowLong(hWnd, GWL_EXSTYLE);
                SetWindowLong(hWnd, GWL_EXSTYLE, exStyle | WS_EX_NOACTIVATE | WS_EX_TOPMOST | WS_EX_TOOLWINDOW);
                SetWindowPos(hWnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE | SWP_SHOWWINDOW);
            } catch { }
        }

        public static void RefreshTopmost(IntPtr hWnd) {
            if (hWnd == IntPtr.Zero) return;
            try {
                SetWindowPos(hWnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE | SWP_SHOWWINDOW);
            } catch { }
        }

        public static void ToggleFullscreen(IntPtr scrcpyHwnd) {
            try {
                if (scrcpyHwnd != IntPtr.Zero) {
                    SetForegroundWindow(scrcpyHwnd);
                    Thread.Sleep(40);
                }
                // Send F11 key down and up
                keybd_event(VK_F11, 0, 0, UIntPtr.Zero);
                keybd_event(VK_F11, 0, 2, UIntPtr.Zero);
            } catch { }
        }

        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        private static extern IntPtr SetWindowsHookEx(int idHook, LowLevelKeyboardProc lpfn, IntPtr hMod, uint dwThreadId);

        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool UnhookWindowsHookEx(IntPtr hhk);

        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);

        [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        private static extern IntPtr GetModuleHandle(string lpModuleName);

        [DllImport("user32.dll")]
        public static extern IntPtr GetForegroundWindow();

        [DllImport("user32.dll")]
        public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

        [DllImport("user32.dll")]
        public static extern bool SetForegroundWindow(IntPtr hWnd);

        [DllImport("user32.dll")]
        public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

        [DllImport("user32.dll")]
        public static extern int GetWindowLong(IntPtr hWnd, int nIndex);

        [DllImport("user32.dll")]
        public static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);

        [DllImport("user32.dll")]
        public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);
    }
}
