Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# Paths
$scrcpyPath = "C:\Users\DevBadawi\AppData\Local\Microsoft\WinGet\Packages\Genymobile.scrcpy_Microsoft.Winget.Source_8wekyb3d8bbwe\scrcpy-win64-v5.0.1\scrcpy.exe"
$adbPath = "C:\Users\DevBadawi\AppData\Local\Microsoft\WinGet\Packages\Genymobile.scrcpy_Microsoft.Winget.Source_8wekyb3d8bbwe\scrcpy-win64-v5.0.1\adb.exe"

# Import Engine Modules
. (Join-Path $PSScriptRoot "DeviceEngine.ps1")
. (Join-Path $PSScriptRoot "DisplayManager.ps1")

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="OmniScreen — Universal Virtual Screen &amp; Device Bridge"
        Height="700" Width="840"
        WindowStartupLocation="CenterScreen"
        Background="#0F172A"
        FontFamily="Segoe UI"
        Foreground="#F8FAFC"
        ResizeMode="CanResize">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Padding" Value="14,10"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}"
                                CornerRadius="8"
                                Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="RadioButton">
            <Setter Property="Foreground" Value="#E2E8F0"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Margin" Value="0,6"/>
        </Style>
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="#CBD5E1"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Margin" Value="0,4"/>
        </Style>
    </Window.Resources>

    <Grid Margin="24">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/> <!-- Header -->
            <RowDefinition Height="Auto"/> <!-- Live Sensor Bar -->
            <RowDefinition Height="*"/>    <!-- Main Config & Controls -->
            <RowDefinition Height="Auto"/> <!-- Hover Top Bar Tips -->
            <RowDefinition Height="Auto"/> <!-- Footer Status -->
        </Grid.RowDefinitions>

        <!-- HEADER -->
        <Grid Grid.Row="0" Margin="0,0,0,16">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <StackPanel Grid.Column="0">
                <TextBlock Text="OmniScreen" FontSize="26" FontWeight="Bold" Foreground="#38BDF8"/>
                <TextBlock Text="Universal Virtual Display, Samsung Mobile Bridge &amp; Console Capture"
                           FontSize="12" Foreground="#94A3B8" Margin="0,2,0,0"/>
            </StackPanel>
            <Button x:Name="BtnRefresh" Grid.Column="1" Content="↻ Refresh Hardware" Background="#334155"
                    Padding="12,6" FontSize="12" VerticalAlignment="Center"/>
        </Grid>

        <!-- LIVE SENSOR STATUS BAR -->
        <Border Grid.Row="1" Background="#1E293B" CornerRadius="10" Padding="16,12" Margin="0,0,0,16">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>

                <!-- Phone Sensor -->
                <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center">
                    <Ellipse x:Name="DotPhone" Width="12" Height="12" Fill="#E2E8F0" Margin="0,0,10,0"/>
                    <StackPanel>
                        <TextBlock Text="Mobile Device (Verified)" FontSize="11" Foreground="#94A3B8" FontWeight="SemiBold"/>
                        <TextBlock x:Name="TxtPhoneStatus" Text="Scanning USB..." FontSize="13" Foreground="#F8FAFC" FontWeight="Bold"/>
                    </StackPanel>
                </StackPanel>

                <!-- Capture Card Sensor -->
                <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                    <Ellipse x:Name="DotCapture" Width="12" Height="12" Fill="#E2E8F0" Margin="0,0,10,0"/>
                    <StackPanel>
                        <TextBlock Text="HDMI Capture Card (PS4 / Chromecast)" FontSize="11" Foreground="#94A3B8" FontWeight="SemiBold"/>
                        <TextBlock x:Name="TxtCaptureStatus" Text="Scanning..." FontSize="13" Foreground="#F8FAFC" FontWeight="Bold"/>
                    </StackPanel>
                </StackPanel>
            </Grid>
        </Border>

        <!-- MAIN CARD -->
        <Border Grid.Row="2" Background="#1E293B" CornerRadius="12" Padding="20" Margin="0,0,0,16">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <!-- Step 1: Mode Selection -->
                <TextBlock Grid.Row="0" Text="1. Choose Display Mode" FontSize="15" FontWeight="Bold" Foreground="#38BDF8" Margin="0,0,0,8"/>
                
                <StackPanel Grid.Row="1" Margin="0,0,0,16">
                    <RadioButton x:Name="RbPhoneMirror" IsChecked="True">
                        <StackPanel>
                            <TextBlock Text="📱 Phone Workspace &amp; Live Apps (Recommended)" FontWeight="Bold" Foreground="#F8FAFC"/>
                            <TextBlock Text="Access all your currently opened apps, background tasks, recent apps, and notifications with mouse and keyboard."
                                       FontSize="11" Foreground="#94A3B8"/>
                        </StackPanel>
                    </RadioButton>
                    
                    <RadioButton x:Name="RbVirtualDesktop">
                        <StackPanel>
                            <TextBlock Text="🖥️ Extended 1080p Virtual Desktop" FontWeight="Bold" Foreground="#F8FAFC"/>
                            <TextBlock Text="Creates an independent 1920x1080 landscape virtual desktop space inside your laptop."
                                       FontSize="11" Foreground="#94A3B8"/>
                        </StackPanel>
                    </RadioButton>

                    <RadioButton x:Name="RbCaptureCard">
                        <StackPanel>
                            <TextBlock Text="🎮 Console &amp; Chromecast Display" FontWeight="Bold" Foreground="#F8FAFC"/>
                            <TextBlock Text="PlayStation 4, Nintendo Switch, or Chromecast via USB HDMI Video Capture Card."
                                       FontSize="11" Foreground="#94A3B8"/>
                        </StackPanel>
                    </RadioButton>
                </StackPanel>

                <!-- Step 2: Session Options & Audio -->
                <Grid Grid.Row="2" Margin="0,0,0,16">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>

                    <!-- Preferences -->
                    <StackPanel Grid.Column="0" Margin="0,0,10,0">
                        <TextBlock Text="2. Display Preferences" FontSize="14" FontWeight="Bold" Foreground="#38BDF8" Margin="0,0,0,8"/>
                        <CheckBox x:Name="ChkFullscreen" Content="Start in True Fullscreen (Adaptive)" IsChecked="True"/>
                        <CheckBox x:Name="ChkWindowsKey" Content="Windows Key Smart Intercept" IsChecked="True"/>
                        <CheckBox x:Name="ChkScreenOff" Content="Power Saver: Phone screen off" IsChecked="False"/>
                        <CheckBox x:Name="ChkTopBar" Content="Enable Hover Top Bar" IsChecked="True"/>
                    </StackPanel>

                    <!-- Audio Destination -->
                    <StackPanel Grid.Column="1" Margin="10,0,0,0">
                        <TextBlock Text="3. Audio Output (Sound)" FontSize="14" FontWeight="Bold" Foreground="#38BDF8" Margin="0,0,0,8"/>
                        <RadioButton x:Name="RbAudioLaptop" GroupName="AudioGroup" IsChecked="True" Content="🔊 Laptop Speakers (Default)"/>
                        <RadioButton x:Name="RbAudioPhone" GroupName="AudioGroup" Content="📱 Phone Speakers"/>
                        <RadioButton x:Name="RbAudioBoth" GroupName="AudioGroup" Content="🎧 Both (Laptop &amp; Phone)"/>
                    </StackPanel>
                </Grid>

                <!-- Step 3: Big Launch Button -->
                <Button x:Name="BtnLaunch" Grid.Row="3" Content="▶  LAUNCH DISPLAY SESSION"
                        Background="#2563EB" Height="48" FontSize="15" FontWeight="Bold"/>
            </Grid>
        </Border>

        <!-- TOP BAR & CONTROLS GUIDE -->
        <Border Grid.Row="3" Background="#1E293B" CornerRadius="10" Padding="14,10" Margin="0,0,0,10">
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                <TextBlock Text="💡 Top Hover Bar: " FontWeight="Bold" Foreground="#38BDF8" FontSize="12" VerticalAlignment="Center"/>
                <TextBlock Text="Hover mouse at top of screen to Exit Fullscreen [🗗], View Recent Apps [📱], or Close [✖]"
                           Foreground="#CBD5E1" FontSize="12" VerticalAlignment="Center"/>
                <TextBlock Text="•" Foreground="#64748B" Margin="10,0" VerticalAlignment="Center"/>
                <TextBlock Text="F11: Toggle Window [X]" Foreground="#CBD5E1" FontSize="12" VerticalAlignment="Center"/>
            </StackPanel>
        </Border>

        <!-- FOOTER LOG -->
        <TextBlock x:Name="TxtLog" Grid.Row="4" Text="OmniScreen ready." FontSize="11" Foreground="#64748B" HorizontalAlignment="Center"/>
    </Grid>
</Window>
"@

$reader = [System.Xml.XmlNodeReader]::new($xaml)
$window = [System.Windows.Markup.XamlReader]::Load($reader)

# Element References
$dotPhone = $window.FindName("DotPhone")
$txtPhoneStatus = $window.FindName("TxtPhoneStatus")
$dotCapture = $window.FindName("DotCapture")
$txtCaptureStatus = $window.FindName("TxtCaptureStatus")
$btnRefresh = $window.FindName("BtnRefresh")
$rbPhoneMirror = $window.FindName("RbPhoneMirror")
$rbVirtualDesktop = $window.FindName("RbVirtualDesktop")
$rbCaptureCard = $window.FindName("RbCaptureCard")
$chkFullscreen = $window.FindName("ChkFullscreen")
$chkWindowsKey = $window.FindName("ChkWindowsKey")
$chkScreenOff = $window.FindName("ChkScreenOff")
$chkTopBar = $window.FindName("ChkTopBar")
$rbAudioLaptop = $window.FindName("RbAudioLaptop")
$rbAudioPhone = $window.FindName("RbAudioPhone")
$rbAudioBoth = $window.FindName("RbAudioBoth")
$btnLaunch = $window.FindName("BtnLaunch")
$txtLog = $window.FindName("TxtLog")

$global:DeviceModel = "Samsung Galaxy S25 FE"

# Status Update Routine
$UpdateStatus = {
    $phone = Get-ConnectedPhoneInfo -AdbPath $adbPath
    if ($phone.Status -eq "Connected") {
        $global:DeviceModel = $phone.FriendlyName
        $txtPhoneStatus.Text = "$($phone.FriendlyName) ($($phone.Model))"
        $dotPhone.Fill = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#10B981") # Green
        $txtPhoneStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#34D399")
    } elseif ($phone.Status -eq "Unauthorized") {
        $txtPhoneStatus.Text = $phone.Message
        $dotPhone.Fill = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F59E0B") # Yellow
        $txtPhoneStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FBBF24")
    } else {
        $txtPhoneStatus.Text = $phone.Message
        $dotPhone.Fill = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#EF4444") # Red
        $txtPhoneStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F87171")
    }

    $cap = Get-ConnectedCaptureCardInfo
    if ($cap.Status -eq "Connected") {
        $txtCaptureStatus.Text = "Ready ($($cap.FriendlyName))"
        $dotCapture.Fill = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#10B981") # Green
        $txtCaptureStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#34D399")
    } else {
        $txtCaptureStatus.Text = $cap.FriendlyName
        $dotCapture.Fill = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#64748B") # Gray
        $txtCaptureStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#94A3B8")
    }
}

& $UpdateStatus

$btnRefresh.Add_Click({
    & $UpdateStatus
    $txtLog.Text = "Hardware refreshed at $(Get-Date -Format 'HH:mm:ss')"
})

# Launch Action
$btnLaunch.Add_Click({
    if ($rbCaptureCard.IsChecked) {
        $txtLog.Text = "Launching HDMI Capture Card Feed..."
        Start-Process "microsoft.windows.camera:"
        return
    }

    $mode = if ($rbVirtualDesktop.IsChecked) { "VirtualDesktop" } else { "Mirror" }
    $fs = [bool]$chkFullscreen.IsChecked
    $so = [bool]$chkScreenOff.IsChecked
    $audio = if ($rbAudioPhone.IsChecked) { "Phone" } elseif ($rbAudioBoth.IsChecked) { "Both" } else { "Laptop" }

    $txtLog.Text = "Launching $global:DeviceModel session ($audio Audio)..."
    Start-OmniScreenSession -ScrcpyPath $scrcpyPath `
                            -AdbPath $adbPath `
                            -Mode $mode `
                            -Fullscreen $fs `
                            -ScreenOff $so `
                            -AudioOutput $audio `
                            -DeviceModel $global:DeviceModel
})

# Auto poll every 4 seconds
$timer = [System.Windows.Threading.DispatcherTimer]::new()
$timer.Interval = [TimeSpan]::FromSeconds(4)
$timer.Add_Tick({ & $UpdateStatus })
$timer.Start()

$window.Add_Closed({
    $timer.Stop()
    try { [OmniScreen.KeyboardHook]::Uninstall() } catch { }
})

$window.ShowDialog() | Out-Null
