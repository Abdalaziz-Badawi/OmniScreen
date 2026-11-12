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
        Title="OmniScreen — Universal Virtual Display &amp; Device Bridge"
        Height="760" Width="1040"
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
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Margin" Value="0,0,16,0"/>
        </Style>
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="#CBD5E1"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Margin" Value="0,0,16,0"/>
        </Style>
    </Window.Resources>

    <Grid Margin="22">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/> <!-- Header -->
            <RowDefinition Height="Auto"/> <!-- Sensor Bar -->
            <RowDefinition Height="*"/>    <!-- 3 Separated Display Mode Cards -->
            <RowDefinition Height="Auto"/> <!-- Shared Settings & Audio Panel -->
            <RowDefinition Height="Auto"/> <!-- Quick Help -->
            <RowDefinition Height="Auto"/> <!-- Footer Status -->
        </Grid.RowDefinitions>

        <!-- HEADER -->
        <Grid Grid.Row="0" Margin="0,0,0,14">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <StackPanel Grid.Column="0">
                <TextBlock Text="OmniScreen" FontSize="26" FontWeight="Bold" Foreground="#38BDF8"/>
                <TextBlock Text="Universal Virtual Display, Samsung Mobile Bridge &amp; Console Capture"
                           FontSize="12" Foreground="#94A3B8" Margin="0,2,0,0"/>
            </StackPanel>
            <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                <Button x:Name="BtnStopAll" Content="⏹ Stop Screen Session" Background="#EF4444"
                        Padding="14,7" FontSize="12" Margin="0,0,10,0" ToolTip="Terminate active virtual display or screen mirror"/>
                <Button x:Name="BtnRefresh" Content="↻ Refresh Hardware" Background="#334155"
                        Padding="12,7" FontSize="12"/>
            </StackPanel>
        </Grid>

        <!-- SENSOR STATUS BAR -->
        <Border Grid.Row="1" Background="#1E293B" CornerRadius="10" Padding="14,10" Margin="0,0,0,16">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>

                <!-- Phone Sensor -->
                <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center">
                    <Ellipse x:Name="DotPhone" Width="12" Height="12" Fill="#E2E8F0" Margin="0,0,10,0"/>
                    <StackPanel>
                        <TextBlock Text="Mobile Device (Verified)" FontSize="10" Foreground="#94A3B8" FontWeight="SemiBold"/>
                        <TextBlock x:Name="TxtPhoneStatus" Text="Scanning USB..." FontSize="13" Foreground="#F8FAFC" FontWeight="Bold"/>
                    </StackPanel>
                </StackPanel>

                <!-- Capture Card Sensor -->
                <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                    <Ellipse x:Name="DotCapture" Width="12" Height="12" Fill="#E2E8F0" Margin="0,0,10,0"/>
                    <StackPanel>
                        <TextBlock Text="HDMI Capture Card (PS4 / Chromecast)" FontSize="10" Foreground="#94A3B8" FontWeight="SemiBold"/>
                        <TextBlock x:Name="TxtCaptureStatus" Text="Scanning..." FontSize="13" Foreground="#F8FAFC" FontWeight="Bold"/>
                    </StackPanel>
                </StackPanel>
            </Grid>
        </Border>

        <!-- 3 DISTINCT, SEPARATED DISPLAY MODE CARDS -->
        <Grid Grid.Row="2" Margin="0,0,0,16">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="14"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="14"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>

            <!-- CARD 1: PHONE WORKSPACE -->
            <Border Grid.Column="0" Background="#1E293B" CornerRadius="12" BorderBrush="#3B82F6" BorderThickness="0,3,0,0" Padding="16">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>

                    <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="0,0,0,6">
                        <TextBlock Text="📱" FontSize="20" Margin="0,0,8,0"/>
                        <TextBlock Text="Phone Workspace" FontSize="16" FontWeight="Bold" Foreground="#60A5FA" VerticalAlignment="Center"/>
                    </StackPanel>
                    
                    <TextBlock Grid.Row="1" Text="Live phone screen with all your active apps, background tasks, and notifications."
                               TextWrapping="Wrap" Foreground="#94A3B8" FontSize="11" Margin="0,0,0,14"/>

                    <StackPanel Grid.Row="2" Margin="0,0,0,14">
                        <TextBlock Text="✔ Mirrors active phone screen" Foreground="#CBD5E1" FontSize="11" Margin="0,3"/>
                        <TextBlock Text="✔ View all open background apps" Foreground="#CBD5E1" FontSize="11" Margin="0,3"/>
                        <TextBlock Text="✔ Keyboard, mouse &amp; touch control" Foreground="#CBD5E1" FontSize="11" Margin="0,3"/>
                        <TextBlock Text="✔ 60 FPS hardware accelerated" Foreground="#CBD5E1" FontSize="11" Margin="0,3"/>
                        <TextBlock Text="✔ Native audio forwarding" Foreground="#CBD5E1" FontSize="11" Margin="0,3"/>
                    </StackPanel>

                    <Button x:Name="BtnLaunchMirror" Grid.Row="3" Content="▶ Start Phone Screen"
                            Background="#2563EB" Height="42" FontSize="13" FontWeight="Bold"/>
                </Grid>
            </Border>

            <!-- CARD 2: EXTENDED VIRTUAL DESKTOP -->
            <Border Grid.Column="2" Background="#1E293B" CornerRadius="12" BorderBrush="#8B5CF6" BorderThickness="0,3,0,0" Padding="16">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>

                    <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="0,0,0,6">
                        <TextBlock Text="🖥️" FontSize="20" Margin="0,0,8,0"/>
                        <TextBlock Text="Virtual Desktop" FontSize="16" FontWeight="Bold" Foreground="#A78BFA" VerticalAlignment="Center"/>
                    </StackPanel>
                    
                    <TextBlock Grid.Row="1" Text="Independent 1920×1080 landscape virtual desktop workspace inside your laptop."
                               TextWrapping="Wrap" Foreground="#94A3B8" FontSize="11" Margin="0,0,0,14"/>

                    <StackPanel Grid.Row="2" Margin="0,0,0,14">
                        <TextBlock Text="✔ Standalone 1080p secondary screen" Foreground="#CBD5E1" FontSize="11" Margin="0,3"/>
                        <TextBlock Text="✔ Phone screen stays free for other use" Foreground="#CBD5E1" FontSize="11" Margin="0,3"/>
                        <TextBlock Text="✔ Dynamic 16:9 adaptive aspect ratio" Foreground="#CBD5E1" FontSize="11" Margin="0,3"/>
                        <TextBlock Text="✔ DeX-style multi-window environment" Foreground="#CBD5E1" FontSize="11" Margin="0,3"/>
                        <TextBlock Text="✔ Zero stretch, zero black bars" Foreground="#CBD5E1" FontSize="11" Margin="0,3"/>
                    </StackPanel>

                    <Button x:Name="BtnLaunchDesktop" Grid.Row="3" Content="🖥️ Start Virtual Desktop"
                            Background="#7C3AED" Height="42" FontSize="13" FontWeight="Bold"/>
                </Grid>
            </Border>

            <!-- CARD 3: CONSOLE & CHROMECAST -->
            <Border Grid.Column="4" Background="#1E293B" CornerRadius="12" BorderBrush="#10B981" BorderThickness="0,3,0,0" Padding="16">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>

                    <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="0,0,0,6">
                        <TextBlock Text="🎮" FontSize="20" Margin="0,0,8,0"/>
                        <TextBlock Text="Console / Chromecast" FontSize="16" FontWeight="Bold" Foreground="#34D399" VerticalAlignment="Center"/>
                    </StackPanel>
                    
                    <TextBlock Grid.Row="1" Text="PlayStation 4, Nintendo Switch, or Chromecast via USB HDMI Video Capture Card."
                               TextWrapping="Wrap" Foreground="#94A3B8" FontSize="11" Margin="0,0,0,14"/>

                    <StackPanel Grid.Row="2" Margin="0,0,0,14">
                        <TextBlock Text="✔ Fullscreen 1080p 60Hz console play" Foreground="#CBD5E1" FontSize="11" Margin="0,3"/>
                        <TextBlock Text="✔ Zero-latency DirectShow capture" Foreground="#CBD5E1" FontSize="11" Margin="0,3"/>
                        <TextBlock Text="✔ Full audio routed to laptop speakers" Foreground="#CBD5E1" FontSize="11" Margin="0,3"/>
                        <TextBlock Text="✔ 16:9 native ratio matches laptop" Foreground="#CBD5E1" FontSize="11" Margin="0,3"/>
                        <TextBlock Text="✔ Plug-and-play with any USB UVC card" Foreground="#CBD5E1" FontSize="11" Margin="0,3"/>
                    </StackPanel>

                    <Button x:Name="BtnLaunchCapture" Grid.Row="3" Content="🎮 Start Console Feed"
                            Background="#059669" Height="42" FontSize="13" FontWeight="Bold"/>
                </Grid>
            </Border>
        </Grid>

        <!-- SHARED SETTINGS & AUDIO PANEL -->
        <Border Grid.Row="3" Background="#1E293B" CornerRadius="10" Padding="16,12" Margin="0,0,0,14">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>

                <!-- Audio Destination -->
                <StackPanel Grid.Row="0" Grid.Column="0" Margin="0,0,0,10">
                    <TextBlock Text="🔊 Audio Destination:" FontWeight="Bold" Foreground="#38BDF8" FontSize="12" Margin="0,0,0,8"/>
                    <StackPanel Orientation="Horizontal">
                        <RadioButton x:Name="RbAudioLaptop" GroupName="AudioGroup" IsChecked="True" Content="Laptop Speakers (Default)"/>
                        <RadioButton x:Name="RbAudioPhone" GroupName="AudioGroup" Content="Phone Speakers"/>
                        <RadioButton x:Name="RbAudioBoth" GroupName="AudioGroup" Content="Both (Simultaneous)"/>
                    </StackPanel>
                </StackPanel>

                <!-- Session Toggles -->
                <StackPanel Grid.Row="0" Grid.Column="1" Margin="0,0,0,10">
                    <TextBlock Text="⚙️ Session Toggles:" FontWeight="Bold" Foreground="#38BDF8" FontSize="12" Margin="0,0,0,8"/>
                    <StackPanel Orientation="Horizontal">
                        <CheckBox x:Name="ChkFullscreen" Content="Fullscreen Mode" IsChecked="True"/>
                        <CheckBox x:Name="ChkWindowsKey" Content="Windows Key Intercept" IsChecked="True"/>
                        <CheckBox x:Name="ChkScreenOff" Content="Phone Screen-Off (Power Saver)" IsChecked="False"/>
                    </StackPanel>
                </StackPanel>

                <!-- Desktop UI Scaling (DPI & Element Sizing) -->
                <Border Grid.Row="1" Grid.ColumnSpan="2" BorderBrush="#334155" BorderThickness="0,1,0,0" Padding="0,10,0,0">
                    <Grid>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="Auto"/>
                        </Grid.RowDefinitions>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>

                        <StackPanel Grid.Row="0" Grid.Column="0" Grid.ColumnSpan="2" Orientation="Horizontal" Margin="0,0,0,10">
                            <TextBlock Text="📐 UI Sizing &amp; Density: " FontWeight="Bold" Foreground="#38BDF8" FontSize="12" VerticalAlignment="Center"/>
                            <TextBlock x:Name="TxtDpiBadge" Text="200 DPI (Balanced — Recommended)" FontWeight="Bold" Foreground="#34D399" FontSize="12" VerticalAlignment="Center"/>
                            <TextBlock Text=" — Comfortable DeX buttons, taskbar &amp; lists; still smaller than bloated 240 DPI" Foreground="#94A3B8" FontSize="11" VerticalAlignment="Center" Margin="8,0,0,0"/>
                        </StackPanel>

                        <!-- Fine-tune Slider -->
                        <Slider x:Name="SliderDpi" Grid.Row="1" Grid.Column="0"
                                Minimum="160" Maximum="230" Value="200"
                                TickFrequency="5" IsSnapToTickEnabled="True"
                                VerticalAlignment="Center" Margin="0,0,24,0"/>

                        <!-- Preset Buttons -->
                        <StackPanel Grid.Row="1" Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                            <Button x:Name="BtnDpi180" Content="180 Compact" Background="#334155" Padding="10,5" FontSize="11" Margin="0,0,6,0"/>
                            <Button x:Name="BtnDpi200" Content="200 Balanced (Default)" Background="#7C3AED" Padding="10,5" FontSize="11" Margin="0,0,6,0"/>
                            <Button x:Name="BtnDpi215" Content="215 Comfort" Background="#334155" Padding="10,5" FontSize="11"/>
                        </StackPanel>
                    </Grid>
                </Border>
            </Grid>
        </Border>

        <!-- QUICK HELP & CONTROLS GUIDE -->
        <Border Grid.Row="4" Background="#1E293B" CornerRadius="8" Padding="12,8" Margin="0,0,0,10">
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                <TextBlock Text="💡 Controls: " FontWeight="Bold" Foreground="#38BDF8" FontSize="11" VerticalAlignment="Center"/>
                <TextBlock Text="Click floating [🗗 Fullscreen] widget (or press F11) to toggle Fullscreen / Windowed"
                           Foreground="#CBD5E1" FontSize="11" VerticalAlignment="Center"/>
                <TextBlock Text="•" Foreground="#64748B" Margin="10,0" VerticalAlignment="Center"/>
                <TextBlock Text="Windows Key: Phone Home / Start Screen" Foreground="#CBD5E1" FontSize="11" VerticalAlignment="Center"/>
                <TextBlock Text="•" Foreground="#64748B" Margin="10,0" VerticalAlignment="Center"/>
                <TextBlock Text="Alt + Q: Exit Screen" Foreground="#CBD5E1" FontSize="11" VerticalAlignment="Center"/>
            </StackPanel>
        </Border>

        <!-- FOOTER BAR & DEVELOPER CONTACTS -->
        <Border Grid.Row="5" BorderBrush="#1E293B" BorderThickness="0,1,0,0" Padding="4,8,4,0">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>

                <!-- Status Log on the left -->
                <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center">
                    <TextBlock Text="● " Foreground="#10B981" FontSize="9" VerticalAlignment="Center" Margin="0,0,4,0"/>
                    <TextBlock Text="Status: " FontSize="11" FontWeight="SemiBold" Foreground="#64748B" VerticalAlignment="Center"/>
                    <TextBlock x:Name="TxtLog" Text="OmniScreen ready." FontSize="11" Foreground="#94A3B8" VerticalAlignment="Center"/>
                </StackPanel>

                <!-- Developer Profile & Contacts on the right -->
                <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                    <TextBlock FontSize="11" Foreground="#64748B" VerticalAlignment="Center">
                        <Run Text="Created by "/>
                        <Bold><Run Text="Abdalaziz Badawi" Foreground="#F8FAFC"/></Bold>
                        <Run Text="  |  " Foreground="#334155"/>
                    </TextBlock>

                    <!-- GitHub Profile -->
                    <TextBlock FontSize="11" VerticalAlignment="Center" Margin="0,0,10,0">
                        <Hyperlink x:Name="LinkGithub" NavigateUri="https://github.com/Abdalaziz-Badawi"
                                   Foreground="#38BDF8" TextDecorations="{x:Null}" Cursor="Hand">
                            <Run Text="🐙 GitHub"/>
                        </Hyperlink>
                    </TextBlock>

                    <TextBlock Text="•" Foreground="#334155" FontSize="11" VerticalAlignment="Center" Margin="0,0,10,0"/>

                    <!-- Email Contact -->
                    <TextBlock FontSize="11" VerticalAlignment="Center" Margin="0,0,10,0">
                        <Hyperlink x:Name="LinkEmail" NavigateUri="mailto:dev.badawi@gmail.com"
                                   Foreground="#38BDF8" TextDecorations="{x:Null}" Cursor="Hand">
                            <Run Text="✉️ dev.badawi@gmail.com"/>
                        </Hyperlink>
                    </TextBlock>

                    <TextBlock Text="•" Foreground="#334155" FontSize="11" VerticalAlignment="Center" Margin="0,0,10,0"/>

                    <!-- GitHub Repo -->
                    <TextBlock FontSize="11" VerticalAlignment="Center">
                        <Hyperlink x:Name="LinkRepo" NavigateUri="https://github.com/Abdalaziz-Badawi/OmniScreen"
                                   Foreground="#A78BFA" TextDecorations="{x:Null}" Cursor="Hand">
                            <Run Text="⭐ OmniScreen Repo"/>
                        </Hyperlink>
                    </TextBlock>
                </StackPanel>
            </Grid>
        </Border>
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
$btnStopAll = $window.FindName("BtnStopAll")

$btnLaunchMirror = $window.FindName("BtnLaunchMirror")
$btnLaunchDesktop = $window.FindName("BtnLaunchDesktop")
$btnLaunchCapture = $window.FindName("BtnLaunchCapture")

$rbAudioLaptop = $window.FindName("RbAudioLaptop")
$rbAudioPhone = $window.FindName("RbAudioPhone")
$rbAudioBoth = $window.FindName("RbAudioBoth")

$chkFullscreen = $window.FindName("ChkFullscreen")
$chkWindowsKey = $window.FindName("ChkWindowsKey")
$chkScreenOff = $window.FindName("ChkScreenOff")
$sliderDpi = $window.FindName("SliderDpi")
$txtDpiBadge = $window.FindName("TxtDpiBadge")
$btnDpi180 = $window.FindName("BtnDpi180")
$btnDpi200 = $window.FindName("BtnDpi200")
$btnDpi215 = $window.FindName("BtnDpi215")
$txtLog = $window.FindName("TxtLog")

# Developer & Contacts Hyperlinks
$linkGithub = $window.FindName("LinkGithub")
$linkEmail = $window.FindName("LinkEmail")
$linkRepo = $window.FindName("LinkRepo")

$OpenUrl = {
    param([string]$url)
    try {
        $psi = [System.Diagnostics.ProcessStartInfo]::new($url)
        $psi.UseShellExecute = $true
        [System.Diagnostics.Process]::Start($psi) | Out-Null
    } catch {
        Start-Process $url
    }
}

if ($linkGithub) {
    $linkGithub.Add_RequestNavigate({
        param($s, $e)
        & $OpenUrl $e.Uri.AbsoluteUri
        $e.Handled = $true
    })
}
if ($linkEmail) {
    $linkEmail.Add_RequestNavigate({
        param($s, $e)
        & $OpenUrl $e.Uri.AbsoluteUri
        $e.Handled = $true
    })
}
if ($linkRepo) {
    $linkRepo.Add_RequestNavigate({
        param($s, $e)
        & $OpenUrl $e.Uri.AbsoluteUri
        $e.Handled = $true
    })
}

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

$global:OnSessionTerminated = {
    $btnLaunchMirror.Content = "▶ Start Phone Screen"
    $btnLaunchDesktop.Content = "🖥️ Start Virtual Desktop"
    $txtLog.Text = "Screen session ended. Ready."
}

$btnStopAll.Add_Click({
    Stop-OmniScreenSession
    $txtLog.Text = "All active screen sessions stopped."
    $btnLaunchMirror.Content = "▶ Start Phone Screen"
    $btnLaunchDesktop.Content = "🖥️ Start Virtual Desktop"
})

# Helper function to get current audio selection
function Get-SelectedAudio {
    if ($rbAudioPhone.IsChecked) { return "Phone" }
    if ($rbAudioBoth.IsChecked) { return "Both" }
    return "Laptop"
}

# UI Density & Slider Routine
$UpdateDpiDisplay = {
    $val = [int]$sliderDpi.Value
    if ($val -eq 200) {
        $txtDpiBadge.Text = "200 DPI (Balanced — Recommended)"
        $txtDpiBadge.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#34D399")
        $btnDpi200.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#7C3AED")
        $btnDpi180.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#334155")
        $btnDpi215.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#334155")
    } elseif ($val -lt 190) {
        $txtDpiBadge.Text = "$val DPI (Compact Desktop)"
        $txtDpiBadge.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#38BDF8")
        $btnDpi180.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2563EB")
        $btnDpi200.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#334155")
        $btnDpi215.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#334155")
    } elseif ($val -gt 210) {
        $txtDpiBadge.Text = "$val DPI (Comfort Desktop — Larger Buttons & Lists)"
        $txtDpiBadge.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FBBF24")
        $btnDpi215.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D97706")
        $btnDpi200.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#334155")
        $btnDpi180.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#334155")
    } else {
        $txtDpiBadge.Text = "$val DPI (Balanced Desktop)"
        $txtDpiBadge.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#A78BFA")
        $btnDpi200.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#334155")
        $btnDpi180.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#334155")
        $btnDpi215.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#334155")
    }
}

if ($sliderDpi) {
    $sliderDpi.Add_ValueChanged({ & $UpdateDpiDisplay })
}
if ($btnDpi180) {
    $btnDpi180.Add_Click({ $sliderDpi.Value = 180; & $UpdateDpiDisplay })
}
if ($btnDpi200) {
    $btnDpi200.Add_Click({ $sliderDpi.Value = 200; & $UpdateDpiDisplay })
}
if ($btnDpi215) {
    $btnDpi215.Add_Click({ $sliderDpi.Value = 215; & $UpdateDpiDisplay })
}

# Helper function to get current desktop DPI selection
function Get-SelectedDpi {
    if ($sliderDpi) {
        return [int]$sliderDpi.Value
    }
    return 200
}

# Launch Card 1: Phone Workspace (Live Screen & Open Apps)
$btnLaunchMirror.Add_Click({
    $fs = [bool]$chkFullscreen.IsChecked
    $so = [bool]$chkScreenOff.IsChecked
    $wk = [bool]$chkWindowsKey.IsChecked
    $audio = Get-SelectedAudio

    $txtLog.Text = "Starting $global:DeviceModel (Live Apps & Screen)..."
    $btnLaunchMirror.Content = "⏳ Starting..."

    $proc = Start-OmniScreenSession -ScrcpyPath $scrcpyPath `
                                    -AdbPath $adbPath `
                                    -Mode "Mirror" `
                                    -Fullscreen $fs `
                                    -ScreenOff $so `
                                    -WindowsKeyIntercept $wk `
                                    -AudioOutput $audio `
                                    -DeviceModel $global:DeviceModel
    if ($proc -and -not $proc.HasExited) {
        $txtLog.Text = "Phone Screen active. Floating [🗗 Fullscreen] widget and Windows Key mapped to Home."
        $btnLaunchMirror.Content = "✔ Running (Click to Restart)"
    } else {
        $txtLog.Text = "Failed to launch screen. Verify USB debugging is authorized on your phone."
        $btnLaunchMirror.Content = "▶ Start Phone Screen"
    }
})

# Launch Card 2: Extended 1080p Virtual Desktop
$btnLaunchDesktop.Add_Click({
    $fs = [bool]$chkFullscreen.IsChecked
    $so = [bool]$chkScreenOff.IsChecked
    $wk = [bool]$chkWindowsKey.IsChecked
    $audio = Get-SelectedAudio
    $dpi = Get-SelectedDpi

    $txtLog.Text = "Starting 1080p Virtual Desktop Workspace (${dpi} DPI)..."
    $btnLaunchDesktop.Content = "⏳ Starting..."

    $proc = Start-OmniScreenSession -ScrcpyPath $scrcpyPath `
                                    -AdbPath $adbPath `
                                    -Mode "VirtualDesktop" `
                                    -Fullscreen $fs `
                                    -ScreenOff $so `
                                    -WindowsKeyIntercept $wk `
                                    -AudioOutput $audio `
                                    -DeviceModel $global:DeviceModel `
                                    -DesktopDpi $dpi
    if ($proc -and -not $proc.HasExited) {
        $txtLog.Text = "Virtual Desktop active (${dpi} DPI). Floating [🗗 Fullscreen] widget and Windows Key mapped to Start."
        $btnLaunchDesktop.Content = "✔ Running (Click to Restart)"
    } else {
        $txtLog.Text = "Failed to launch virtual desktop. Verify USB connection."
        $btnLaunchDesktop.Content = "🖥️ Start Virtual Desktop"
    }
})

# Launch Card 3: Console / Chromecast Feed
$btnLaunchCapture.Add_Click({
    $viewerHtml = Join-Path $PSScriptRoot "ConsoleViewer.html"
    $txtLog.Text = "Opening Dedicated Console / Chromecast Display..."
    
    # Launch in standalone application mode (no address bar, no camera UI, pure gaming screen)
    Start-Process "msedge.exe" -ArgumentList "--app=""file:///$viewerHtml"" --start-fullscreen"
})

# Auto poll hardware every 4 seconds
$timer = [System.Windows.Threading.DispatcherTimer]::new()
$timer.Interval = [TimeSpan]::FromSeconds(4)
$timer.Add_Tick({ & $UpdateStatus })
$timer.Start()

$window.Add_Closed({
    $timer.Stop()
    Stop-OmniScreenSession
})

$window.ShowDialog() | Out-Null
