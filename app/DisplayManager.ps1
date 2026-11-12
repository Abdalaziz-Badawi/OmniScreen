# DisplayManager.ps1 - Screen Session Controller for OmniScreen

# Ensure Keyboard Hook is compiled & loaded
$hookPath = Join-Path $PSScriptRoot "KeyboardHook.cs"
if (-not ([System.Management.Automation.PSTypeName]'OmniScreen.KeyboardHook').Type) {
    Add-Type -Path $hookPath
}

# Load Fullscreen Retractable Toggle Button definition
. (Join-Path $PSScriptRoot "FullscreenToggle.ps1")

# Global session tracker
$global:CurrentSessionProcess = $null
$global:CurrentToggleWindow = $null
$global:SessionCleanupTimer = $null
$global:OnSessionTerminated = $null

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
        [string]$DeviceModel = "Samsung Galaxy S25 FE"
    )

    # 1. Stop any previous session first to prevent conflicts
    Stop-OmniScreenSession
    Start-Sleep -Milliseconds 200

    # 2. Build clean argument array for Scrcpy
    $argsList = [System.Collections.Generic.List[string]]::new()

    # Window title (space-free to prevent argument splitting in Start-Process)
    if ($Mode -eq "VirtualDesktop") {
        $argsList.Add("--window-title=OmniScreen-Desktop")
        $argsList.Add("--new-display=1920x1080/320")
        $argsList.Add("-x")
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
    # Maps Windows Key directly to Android Home / Start Screen (KeyCode 3)
    # Async ThreadPool execution ensures hook NEVER blocks and NEVER drops
    if ($WindowsKeyIntercept) {
        $targetKeyCode = if ($Mode -eq "VirtualDesktop") { 3 } else { 3 }
        [OmniScreen.KeyboardHook]::Install($sessionPid, $AdbPath, $targetKeyCode)
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
        # Never kill scrcpy here!
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

            if ($global:OnSessionTerminated) {
                try { $global:OnSessionTerminated.Invoke() } catch { }
            }
        }
    }.GetNewClosure()

    $global:SessionCleanupTimer.Add_Tick($cleanupAction)
    $global:SessionCleanupTimer.Start()

    return $proc
}
