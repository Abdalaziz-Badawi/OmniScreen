# DeviceEngine.ps1 - Hardware & Device Discovery for OmniScreen

function Get-ConnectedPhoneInfo {
    param([string]$AdbPath = "adb")
    
    try {
        $devicesOutput = & $AdbPath devices -l 2>&1
        
        # Filter out daemon messages and list header
        $cleanLines = $devicesOutput | Where-Object { 
            $_ -and 
            $_ -notmatch '^\s*\*|daemon' -and 
            $_ -notmatch '(?i)List of devices attached'
        }

        # Match any line with the status "device" regardless of usb hub port or formatting
        $deviceLine = $cleanLines | Where-Object { $_ -match '\s+device(\s+|$)' } | Select-Object -First 1

        if (-not $deviceLine) {
            $unauth = $cleanLines | Where-Object { $_ -match 'unauthorized' } | Select-Object -First 1
            if ($unauth) {
                return @{ Status = "Unauthorized"; Message = "Unlock phone & tap 'Allow USB Debugging'" }
            }
            $offline = $cleanLines | Where-Object { $_ -match 'offline' } | Select-Object -First 1
            if ($offline) {
                return @{ Status = "Offline"; Message = "Device Offline (Reconnect USB cable)" }
            }
            return @{ Status = "Disconnected"; Message = "No Phone Connected (Connect USB & enable USB Debugging)" }
        }

        # Extract Serial Number
        $serial = ""
        if ($deviceLine -match '^\s*([^\s]+)\s+device') {
            $serial = $matches[1].Trim()
        }

        # Extract model from adb line if available
        $modelFromLine = ""
        if ($deviceLine -match 'model:([^\s]+)') {
            $modelFromLine = $matches[1].Replace('_', ' ').Trim()
        }

        # Query internal properties using specific serial (-s $serial)
        $serialArg = if ($serial) { @("-s", $serial) } else { @() }

        $model = (& $AdbPath @serialArg shell getprop ro.product.model 2>$null)
        if ($model) { $model = $model.Trim() } elseif ($modelFromLine) { $model = $modelFromLine } else { $model = "Android Device" }

        $brand = (& $AdbPath @serialArg shell getprop ro.product.brand 2>$null)
        if ($brand) { $brand = $brand.Trim() } else { $brand = "Android" }

        $devName = (& $AdbPath @serialArg shell settings get global device_name 2>$null)
        if ($devName) { $devName = $devName.Trim() }

        # Comprehensive Model Map for Samsung & Common Brands
        $friendlyName = switch -Regex ($model) {
            '^SM-S731' { "Samsung Galaxy S25 FE" }
            '^SM-S938' { "Samsung Galaxy S25 Ultra" }
            '^SM-S936' { "Samsung Galaxy S25+" }
            '^SM-S931' { "Samsung Galaxy S25" }
            '^SM-S721' { "Samsung Galaxy S24 FE" }
            '^SM-S928' { "Samsung Galaxy S24 Ultra" }
            '^SM-S926' { "Samsung Galaxy S24+" }
            '^SM-S921' { "Samsung Galaxy S24" }
            '^SM-S711' { "Samsung Galaxy S23 FE" }
            '^SM-S918' { "Samsung Galaxy S23 Ultra" }
            '^SM-S916' { "Samsung Galaxy S23+" }
            '^SM-S911' { "Samsung Galaxy S23" }
            '^SM-F956' { "Samsung Galaxy Z Fold 6" }
            '^SM-F946' { "Samsung Galaxy Z Fold 5" }
            '^SM-F741' { "Samsung Galaxy Z Flip 6" }
            '^SM-F731' { "Samsung Galaxy Z Flip 5" }
            '^SM-N98'  { "Samsung Galaxy Note 20" }
            '^SM-G99'  { "Samsung Galaxy S21" }
            '^SM-G98'  { "Samsung Galaxy S20" }
            '^Pixel'   { "Google $model" }
            default {
                if ($devName -and $devName -ne "null" -and $devName -ne "") {
                    "$brand $devName"
                } else {
                    "$brand $model"
                }
            }
        }

        # Check if device supports Samsung DeX
        $isSamsung = ($brand -match '(?i)samsung' -or $model -match '^SM-')
        $supportsDex = $false
        if ($isSamsung) {
            $dexCheck = (& $AdbPath @serialArg shell pm path com.sec.android.app.desktoplauncher 2>$null)
            if ($dexCheck -match 'desktoplauncher') {
                $supportsDex = $true
            } elseif ($model -match '^SM-(S[7-9]|F9|N[9]|T[89])') {
                $supportsDex = $true
            }
        }

        return @{
            Status       = "Connected"
            FriendlyName = $friendlyName
            Model        = $model
            CustomName   = $devName
            Brand        = $brand
            Serial       = $serial
            SupportsDex  = $supportsDex
        }
    } catch {
        return @{ Status = "Error"; Message = "ADB Error" }
    }
}

function Get-ConnectedCaptureCardInfo {
    try {
        $captureDevices = Get-PnpDevice -PresentOnly -Class Camera, Media, Image -ErrorAction SilentlyContinue |
            Where-Object { $_.FriendlyName -match '(?i)capture|cam\s*link|fhd|hdmi|usb\s*video|uvc' -and $_.FriendlyName -notmatch '(?i)hp wide vision' }
        if ($captureDevices) {
            $dev = $captureDevices | Select-Object -First 1
            return @{
                Status       = "Connected"
                FriendlyName = $dev.FriendlyName
                InstanceId   = $dev.InstanceId
            }
        }
        return @{
            Status       = "Disconnected"
            FriendlyName = "Waiting for Capture Card (USB)"
        }
    } catch {
        return @{ Status = "Error"; FriendlyName = "Sensor Error" }
    }
}
