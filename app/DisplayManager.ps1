# DisplayManager.ps1 - Screen Session Controller for OmniScreen

# Ensure Keyboard Hook is compiled & loaded
$hookPath = Join-Path $PSScriptRoot "KeyboardHook.cs"
if (-not ([System.Management.Automation.PSTypeName]'OmniScreen.KeyboardHook').Type) {
    Add-Type -Path $hookPath
}

# Load Fullscreen Retractable Toggle Button definition
. (Join-Path $PSScriptRoot "FullscreenToggle.ps1")

# Load Standalone Virtual Screen definition
. (Join-Path $PSScriptRoot "VirtualScreen.ps1")

# Global session tracker
$global:CurrentSessionProcess = $null
$global:CurrentToggleWindow = $null
$global:StandaloneVirtualScreenWindow = $null
$global:SessionCleanupTimer = $null
$global:OnSessionTerminated = $null

function Get-VirtualDisplayId {
    param([string]$AdbPath)
    try {
        $dump = & $AdbPath shell dumpsys display
        if (-not $dump) { return "" }
        
        # 1. Match uniqueId="virtual:com.android.shell,2000,scrcpy,(\d+)"
        $m = [regex]::Match($dump, 'DisplayDeviceInfo\{"scrcpy".*?uniqueId="virtual:[^"]*,(\d+)"')
        if ($m.Success) {
            return $m.Groups[1].Value
        }
        # 2. Match Display id (\d+):.*name="scrcpy"
        $m2 = [regex]::Match($dump, 'Display id (\d+):[^\r\n]*name="scrcpy"')
        if ($m2.Success) {
            return $m2.Groups[1].Value
        }
        # 3. Find any non-zero virtual display
        $m3 = [regex]::Match($dump, 'Display id (\d+):[^\r\n]*type=VIRTUAL')
        if ($m3.Success) {
            return $m3.Groups[1].Value
        }
    } catch { }
    return ""
}

function Stop-OmniScreenSession {
    param()

    # 1. Stop cleanup timer if active
    if ($global:SessionCleanupTimer) {
        try {
            $global:SessionCleanupTimer.Stop()
        } catch { }
        $global:SessionCleanupTimer = $null
    }

    # 2. Uninstall Keyboard Hook
    try {
        [OmniScreen.KeyboardHook]::Uninstall()
    } catch { }

    # 3. Close floating toggle window
    if ($global:CurrentToggleWindow) {
        try {
            $global:CurrentToggleWindow.Close()
        } catch { }
        $global:CurrentToggleWindow = $null
    }

    # 3b. Close standalone virtual screen window
    if ($global:StandaloneVirtualScreenWindow) {
        try {
            $global:StandaloneVirtualScreenWindow.Close()
        } catch { }
        $global:StandaloneVirtualScreenWindow = $null
    }

    # 4. Stop active Scrcpy process
    if ($global:CurrentSessionProcess) {
        try {
            $p = $global:CurrentSessionProcess
            $p.Refresh()
            if (-not $p.HasExited) {
                $p.Kill()
                $p.WaitForExit(500)
            }
        } catch { }
        $global:CurrentSessionProcess = $null
    }

    # 5. Cleanup any dangling scrcpy processes
    Get-Process scrcpy -ErrorAction SilentlyContinue | ForEach-Object {
        try { $_.Kill() } catch { }
    }

    # 6. Notify UI
    if ($global:OnSessionTerminated) {
        try { $global:OnSessionTerminated.Invoke() } catch { }
    }
}

function Start-OmniScreenSession {
    param(
        [Parameter(Mandatory=$true)] [string]$ScrcpyPath,
        [Parameter(Mandatory=$true)] [string]$AdbPath,
        [string]$Mode = "Mirror", # "Mirror" or "VirtualDesktop"
        [bool]$Fullscreen = $true,
        [bool]$ScreenOff = $false,
        [bool]$WindowsKeyIntercept = $true,
        [string]$AudioOutput = "Laptop", # "Laptop", "Phone", "Both"
        [string]$DeviceModel = "Samsung Galaxy S25 FE",
        [string]$DeviceSerial = "",
        [int]$DesktopDpi = 200, # 200 = Balanced Desktop (crisp readable text & comfortable buttons; between 160 and 240)
        [bool]$SkipStandaloneFallback = $false
    )

    # If VirtualDesktop is chosen without a connected phone, create Standalone Virtual Screen immediately
    if ($Mode -eq "VirtualDesktop" -and -not $SkipStandaloneFallback) {
        $phone = Get-ConnectedPhoneInfo -AdbPath $AdbPath
        if ($phone.Status -ne "Connected") {
            $global:StandaloneVirtualScreenWindow = Show-StandaloneVirtualScreen -ScrcpyPath $ScrcpyPath `
                                                                                 -AdbPath $AdbPath `
                                                                                 -DesktopDpi $DesktopDpi `
                                                                                 -Fullscreen $Fullscreen `
                                                                                 -ScreenOff $ScreenOff `
                                                                                 -WindowsKeyIntercept $WindowsKeyIntercept `
                                                                                 -AudioOutput $AudioOutput `
                                                                                 -DeviceModel $DeviceModel
            return $global:StandaloneVirtualScreenWindow
        }
    }

    # 0. Automatically unlock Samsung DeX Labs & multi-window resizing for all apps
    # This prevents apps like Notesnook from locking into a narrow portrait strip with gray borders
    $serialArg = if ($DeviceSerial) { @("-s", $DeviceSerial) } else { @() }
    try {
        & $AdbPath @serialArg shell "settings put global enable_non_resizable_multi_window 1; settings put global force_resizable_activities 1; settings put global enable_freeform_support 1; settings put global force_allow_on_external 1"
    } catch { }

    # 1. Stop any previous session first to prevent conflicts
    Stop-OmniScreenSession
    Start-Sleep -Milliseconds 200

    # 2. Build clean argument array for Scrcpy
    $argsList = [System.Collections.Generic.List[string]]::new()

    # Explicit device serial if multiple devices are connected
    if ($DeviceSerial) {
        $argsList.Add("-s")
        $argsList.Add($DeviceSerial)
    }

    # Window title (space-free to prevent argument splitting in Start-Process)
    # Uses selected DPI (default 200) for balanced desktop UI breakpoints.
    # Note: Omit -x (flex-display) so scrcpy uses letterbox scaling to guarantee the
    # entire 1080p frame—including the bottom taskbar—fits cleanly within the laptop screen.
    if ($Mode -eq "VirtualDesktop") {
        $argsList.Add("--window-title=OmniScreen-Desktop")
        $argsList.Add("--new-display=1920x1080/$DesktopDpi")
    } else {
        $argsList.Add("--window-title=OmniScreen-Phone")
    }

    # Fullscreen & Display flags
    if ($Fullscreen) {
        $argsList.Add("-f")
    }
    if ($ScreenOff) {
        $argsList.Add("--turn-screen-off")
    }

    # Performance flags (24M bitrate, 60fps cap, stay awake)
    $argsList.Add("--stay-awake")
    $argsList.Add("--video-bit-rate=24M")
    $argsList.Add("--max-fps=60")

    # Keyboard & shortcut modifier
    $argsList.Add("--shortcut-mod=lalt,ralt")

    # Audio Routing:
    switch ($AudioOutput) {
        "Phone" {
            $argsList.Add("--no-audio")
        }
        "Both" {
            $argsList.Add("--audio-source=playback")
            $argsList.Add("--audio-dup")
            $argsList.Add("--audio-buffer=50")
        }
        default { # "Laptop"
            $argsList.Add("--audio-source=output")
            $argsList.Add("--audio-buffer=50")
        }
    }

    # 3. Launch Scrcpy Process with clean argument array
    $proc = Start-Process -FilePath $ScrcpyPath -ArgumentList $argsList.ToArray() -PassThru
    $global:CurrentSessionProcess = $proc
    $sessionPid = $proc.Id

    # 4. Wait for Scrcpy window to initialize and verify process health
    $scrcpyHwnd = [IntPtr]::Zero
    for ($i = 0; $i -lt 15; $i++) {
        Start-Sleep -Milliseconds 200
        $proc.Refresh()
        if ($proc.HasExited) {
            Write-Warning "Scrcpy process exited unexpectedly with code $($proc.ExitCode)."
            $global:CurrentSessionProcess = $null
            return $null
        }
        if ($proc.MainWindowHandle -ne [IntPtr]::Zero) {
            $scrcpyHwnd = $proc.MainWindowHandle
            break
        }
    }

    # 5. Install Low-Level Keyboard Hook if enabled
    # For Virtual Desktop / DeX: uses KeyCode 117 (KEYCODE_META_LEFT) directed to the DeX display
    # to open the DeX Apps / Start Menu (OverlayAppsDialog)
    # For Mirror mode: uses KeyCode 3 (KEYCODE_HOME) directed to Display 0
    if ($WindowsKeyIntercept) {
        $virtualDisplayId = ""
        $targetKeyCode = 117 # KEYCODE_META_LEFT (DeX Menu)
        
        if ($Mode -eq "VirtualDesktop") {
            for ($d = 0; $d -lt 5; $d++) {
                $virtualDisplayId = Get-VirtualDisplayId -AdbPath $AdbPath
                if ($virtualDisplayId) { break }
                Start-Sleep -Milliseconds 250
            }
            if (-not $virtualDisplayId) {
                $virtualDisplayId = "" # Fallback to default active display
            } else {
                # Ensure the DeX bottom taskbar is actively unhidden / revealed
                try {
                    & $AdbPath shell "input -d $virtualDisplayId swipe 960 1079 960 950 150"
                } catch { }
            }
        } else {
            $virtualDisplayId = "0"
            $targetKeyCode = 3 # KEYCODE_HOME
        }

        [OmniScreen.KeyboardHook]::Install($sessionPid, $AdbPath, $targetKeyCode, $virtualDisplayId)
    }

    # 6. Show Retractable Fullscreen Toggle Button (stays strictly on top)
    $global:CurrentToggleWindow = Show-FullscreenToggleButton -ScrcpyProcess $proc -ScrcpyHwnd $scrcpyHwnd

    # 7. Monitor Scrcpy Process to cleanup hook & window ONLY when scrcpy is closed by the user
    # Uses .GetNewClosure() and process ID checking to avoid variable scoping issues
    $global:SessionCleanupTimer = [System.Windows.Threading.DispatcherTimer]::new()
    $global:SessionCleanupTimer.Interval = [TimeSpan]::FromMilliseconds(1000)

    $cleanupAction = {
        $alive = $false
        try {
            $p = [System.Diagnostics.Process]::GetProcessById($sessionPid)
            if (-not $p.HasExited) {
                $alive = $true
            }
        } catch {
            $alive = $false
        }

        # ONLY cleanup if the process is no longer running (e.g. user pressed Alt+Q or closed window)
        if (-not $alive) {
            if ($global:SessionCleanupTimer) {
                $global:SessionCleanupTimer.Stop()
                $global:SessionCleanupTimer = $null
            }

            try { [OmniScreen.KeyboardHook]::Uninstall() } catch { }

            if ($global:CurrentToggleWindow) {
                try { $global:CurrentToggleWindow.Close() } catch { }
                $global:CurrentToggleWindow = $null
            }

            $global:CurrentSessionProcess = $null

            # If Standalone Virtual Screen was minimized during DeX, restore it
            if ($global:StandaloneVirtualScreenWindow) {
                try {
                    $global:StandaloneVirtualScreenWindow.WindowState = [System.Windows.WindowState]::Normal
                    $global:StandaloneVirtualScreenWindow.Activate()
                } catch { }
            }

            if ($global:OnSessionTerminated) {
                try { $global:OnSessionTerminated.Invoke() } catch { }
            }
        }
    }.GetNewClosure()

    $global:SessionCleanupTimer.Add_Tick($cleanupAction)
    $global:SessionCleanupTimer.Start()

    return $proc
}
