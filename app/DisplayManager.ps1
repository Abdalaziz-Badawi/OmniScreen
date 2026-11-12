# DisplayManager.ps1 - Screen Session Controller for OmniScreen

# Ensure Keyboard Hook is compiled & loaded
$hookPath = Join-Path $PSScriptRoot "KeyboardHook.cs"
if (-not ([System.Management.Automation.PSTypeName]'OmniScreen.KeyboardHook').Type) {
    Add-Type -Path $hookPath
}

# Load Floating Bar definition
. (Join-Path $PSScriptRoot "TopBarOverlay.ps1")

function Start-OmniScreenSession {
    param(
        [Parameter(Mandatory=$true)] [string]$ScrcpyPath,
        [Parameter(Mandatory=$true)] [string]$AdbPath,
        [string]$Mode = "Mirror", # "Mirror" or "VirtualDesktop"
        [bool]$Fullscreen = $true,
        [bool]$ScreenOff = $false,
        [string]$AudioOutput = "Laptop", # "Laptop", "Phone", "Both"
        [string]$DeviceModel = "Samsung Galaxy S25 FE"
    )

    # Base arguments for maximum smoothness & lowest latency:
    # 24M bitrate, 60 FPS cap, 0 buffer display delay, 30ms audio buffer
    $fsArg = if ($Fullscreen) { "-f" } else { "" }
    $soArg = if ($ScreenOff) { "--turn-screen-off" } else { "" }
    
    # Audio routing option:
    # Laptop: Default forwarding to laptop speakers
    # Phone: --no-audio leaves audio strictly on phone speakers
    # Both: --audio-dup plays audio simultaneously on laptop & phone
    $audioArg = switch ($AudioOutput) {
        "Phone"  { "--no-audio" }
        "Both"   { "--audio-source=playback --audio-dup --audio-buffer=30" }
        default  { "--audio-source=playback --audio-buffer=30" } # "Laptop"
    }

    $commonArgs = "--shortcut-mod=lalt,ralt --keyboard=uhid $audioArg --stay-awake --video-bit-rate=24M --max-fps=60 --display-buffer=0"

    $finalArgs = ""
    if ($Mode -eq "VirtualDesktop") {
        $finalArgs = "--window-title=""OmniScreen — Virtual Desktop"" --new-display=1920x1080/320 -x $fsArg $soArg $commonArgs"
    } else {
        # Native Phone Screen Mirror (Displays all running apps, background tasks, recent apps)
        $finalArgs = "--window-title=""OmniScreen — $DeviceModel"" $fsArg $soArg $commonArgs"
    }

    # Launch Scrcpy Process
    $proc = Start-Process -FilePath $ScrcpyPath -ArgumentList $finalArgs -PassThru

    # Install Low-Level Keyboard Hook
    # Intercepts Windows Key: prevents Windows Start Menu & Taskbar from covering screen,
    # and forwards Recent Apps / App Switcher to phone!
    [OmniScreen.KeyboardHook]::OnWindowsKeyPressed = {
        try {
            Start-Process -FilePath $AdbPath -ArgumentList "shell input keyevent 187" -NoNewWindow
        } catch { }
    }
    [OmniScreen.KeyboardHook]::Install()

    # Launch Floating Hover Top Bar (Provides circle / top capsule for Exit Fullscreen, Recent Apps, Home, Close)
    if ($Fullscreen) {
        Show-FloatingTopBar -ScrcpyProcess $proc -AdbPath $AdbPath
    }

    # Monitor Scrcpy Process to cleanup hook upon exit
    $cleanupTimer = [System.Windows.Threading.DispatcherTimer]::new()
    $cleanupTimer.Interval = [TimeSpan]::FromMilliseconds(500)
    $cleanupTimer.Add_Tick({
        if (-not $proc -or $proc.HasExited) {
            $cleanupTimer.Stop()
            [OmniScreen.KeyboardHook]::Uninstall()
        }
    })
    $cleanupTimer.Start()

    return $proc
}
