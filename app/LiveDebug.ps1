# LiveDebug.ps1 - Live Device Diagnostics & Debugging Engine for OmniScreen
$ErrorActionPreference = "Continue"

$scrcpyPath = "C:\Users\DevBadawi\AppData\Local\Microsoft\WinGet\Packages\Genymobile.scrcpy_Microsoft.Winget.Source_8wekyb3d8bbwe\scrcpy-win64-v5.0.1\scrcpy.exe"
$adbPath = "C:\Users\DevBadawi\AppData\Local\Microsoft\WinGet\Packages\Genymobile.scrcpy_Microsoft.Winget.Source_8wekyb3d8bbwe\scrcpy-win64-v5.0.1\adb.exe"

$host.UI.RawUI.WindowTitle = "OmniScreen — Live Device Debugger"

Clear-Host
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "                  OMNISCREEN LIVE DEVICE DEBUGGER & MONITOR                     " -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Query ADB Devices
$devices = & $adbPath devices -l 2>&1 | Where-Object { $_ -match '\s+device(\s+|$)' }
if (-not $devices) {
    Write-Host "[!] No active ADB device found." -ForegroundColor Red
    Write-Host "    Please ensure your phone is connected via USB and USB Debugging is ON." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit..."
    exit 1
}

$deviceLine = $devices | Select-Object -First 1
$serial = if ($deviceLine -match '^\s*([^\s]+)\s+device') { $matches[1].Trim() } else { "" }

Write-Host "[+] Target Device Connected: " -NoNewline -ForegroundColor Green
Write-Host "$serial" -ForegroundColor White

# 2. Gather Real-Time Hardware Info
$brand = (& $adbPath -s $serial shell getprop ro.product.brand 2>$null).Trim()
$model = (& $adbPath -s $serial shell getprop ro.product.model 2>$null).Trim()
$androidVer = (& $adbPath -s $serial shell getprop ro.build.version.release 2>$null).Trim()
$sdkVer = (& $adbPath -s $serial shell getprop ro.build.version.sdk 2>$null).Trim()
$abi = (& $adbPath -s $serial shell getprop ro.product.cpu.abi 2>$null).Trim()

# Battery
$batteryRaw = & $adbPath -s $serial shell dumpsys battery 2>$null
$batLevel = if ($batteryRaw -match 'level:\s*(\d+)') { $matches[1] } else { "N/A" }
$batTemp = if ($batteryRaw -match 'temperature:\s*(\d+)') { [math]::Round([int]$matches[1] / 10, 1) } else { "N/A" }
$batCharging = if ($batteryRaw -match 'USB powered:\s*true') { "USB Charging" } else { "Discharging" }

# Screen
$wmSize = (& $adbPath -s $serial shell wm size 2>$null) -replace 'Physical size:\s*', ''
$wmDensity = (& $adbPath -s $serial shell wm density 2>$null) -replace 'Physical density:\s*', ''

# 3. Print Diagnostics Dashboard
Write-Host ""
Write-Host "--- [ LIVE HARDWARE DIAGNOSTICS ] ----------------------------------------------" -ForegroundColor DarkGray
Write-Host "  * Brand & Model:      " -NoNewline -ForegroundColor Gray
Write-Host "$brand $model" -ForegroundColor Cyan
Write-Host "  * Serial Number:      " -NoNewline -ForegroundColor Gray
Write-Host "$serial" -ForegroundColor White
Write-Host "  * Android Version:    " -NoNewline -ForegroundColor Gray
Write-Host "Android $androidVer (API $sdkVer, $abi)" -ForegroundColor White
Write-Host "  * Display Resolution: " -NoNewline -ForegroundColor Gray
Write-Host "$wmSize ($wmDensity DPI)" -ForegroundColor White
Write-Host "  * Battery State:      " -NoNewline -ForegroundColor Gray
Write-Host "$batLevel% ($batCharging, $batTemp°C)" -ForegroundColor White
Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""

# 4. Launch Live Screen Mirror with Debug Output
Write-Host "[+] Initializing Live Screen Stream with Verbose Debugging..." -ForegroundColor Yellow
$scrcpyArgs = @(
    "-s", $serial,
    "--window-title=OmniScreen Live Debug — $brand $model",
    "--stay-awake",
    "--max-fps=60",
    "--video-bit-rate=16M",
    "-Vdebug"
)

# If Android 10 or lower, omit audio to prevent unsupported audio warning
if ([int]$sdkVer -lt 30) {
    $scrcpyArgs += "--no-audio"
    Write-Host "[i] Note: Android $androidVer detected (API $sdkVer). Video stream active (Audio capture requires Android 11+)." -ForegroundColor DarkGray
}

Write-Host "[+] Launching Live Display Window..." -ForegroundColor Green
Write-Host "    Press Ctrl+C in this console or close the phone window to stop." -ForegroundColor DarkGray
Write-Host ""

& $scrcpyPath @scrcpyArgs
