# DeviceEngine.ps1 - Hardware & Device Discovery for OmniScreen

function Get-ConnectedPhoneInfo {
    param([string]$AdbPath = "adb")
    
    try {
        $devicesOutput = & $AdbPath devices -l 2>&1
        $deviceLine = $devicesOutput | Where-Object { $_ -match '(?i)device\s+product' }
        if (-not $deviceLine) {
            $unauth = $devicesOutput | Where-Object { $_ -match 'unauthorized' }
            if ($unauth) {
                return @{ Status = "Unauthorized"; Message = "Waiting for Phone Permission" }
            }
            return @{ Status = "Disconnected"; Message = "No Phone Connected (Connect USB)" }
        }

        # Query internal properties
        $model = (& $AdbPath shell getprop ro.product.model 2>$null)
        if ($model) { $model = $model.Trim() } else { $model = "Android" }

        $brand = (& $AdbPath shell getprop ro.product.brand 2>$null)
        if ($brand) { $brand = $brand.Trim() } else { $brand = "Samsung" }

        $devName = (& $AdbPath shell settings get global device_name 2>$null)
        if ($devName) { $devName = $devName.Trim() }

        # Comprehensive Model Map
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
            default {
                if ($devName -and $devName -ne "null" -and $devName -ne "") {
                    "$brand $devName"
                } else {
                    "$brand $model"
                }
            }
        }

        return @{
            Status       = "Connected"
            FriendlyName = $friendlyName
            Model        = $model
            CustomName   = $devName
            Brand        = $brand
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
