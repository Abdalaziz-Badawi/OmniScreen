# DisplayManager.ps1 - Screen Session Controller for OmniScreen

# Ensure Keyboard Hook is compiled & loaded
$hookPath = Join-Path $PSScriptRoot "KeyboardHook.cs"
if (-not ([System.Management.Automation.PSTypeName]'OmniScreen.KeyboardHook').Type) {
    Add-Type -Path $hookPath
}

# Load Fullscreen Retractable Toggle Button definition
. (Join-Path $PSScriptRoot "FullscreenToggle.ps1")

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

    # Build clean arguments list
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
    $argsList.Add("--keyboard=uhid")

    # Audio Routing:
    # Laptop: default forwarding to laptop speakers
    # Phone: --no-audio leaves audio strictly on phone speakers
    # Both: --audio-dup plays audio simultaneously on laptop & phone
    switch ($AudioOutput) {
        "Phone" {
            $argsList.Add("--no-audio")
        }
        "Both" {
            $argsList.Add("--audio-source=playback")
            $argsList.Add("--audio-dup")
            $argsList.Add("--audio-buffer=30")
        }
        default { # "Laptop"
            $argsList.Add("--audio-source=playback")
            $argsList.Add("--audio-buffer=30")
        }
    }

    # Launch Scrcpy Process with clean argument array
    $proc = Start-Process -FilePath $ScrcpyPath -ArgumentList $argsList.ToArray() -PassThru

    # Verify process started cleanly
    Start-Sleep -Milliseconds 400
    if ($proc.HasExited) {
        Write-Warning "Scrcpy process exited unexpectedly with code $($proc.ExitCode)."
        return $null
    }

    # Install Low-Level Keyboard Hook if enabled
    if ($WindowsKeyIntercept) {
        [OmniScreen.KeyboardHook]::OnWindowsKeyPressed = {
            try {
                Start-Process -FilePath $AdbPath -ArgumentList "shell input keyevent 187" -NoNewWindow
            } catch { }
        }
        [OmniScreen.KeyboardHook]::Install()
    }

    # Show Retractable Fullscreen Toggle Button (Unobtrusive floating button in the corner)
    Show-FullscreenToggleButton -ScrcpyProcess $proc

    # Monitor Scrcpy Process to cleanup hook upon exit
    $cleanupTimer = [System.Windows.Threading.DispatcherTimer]::new()
    $cleanupTimer.Interval = [TimeSpan]::FromMilliseconds(500)
    $cleanupTimer.Add_Tick({
        if (-not $proc -or $proc.HasExited) {
            $cleanupTimer.Stop()
            if ($WindowsKeyIntercept) {
                [OmniScreen.KeyboardHook]::Uninstall()
            }
        }
    })
    $cleanupTimer.Start()

    return $proc
}
