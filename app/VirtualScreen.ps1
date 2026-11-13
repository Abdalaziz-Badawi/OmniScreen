# VirtualScreen.ps1 - Standalone Virtual Screen & DeX Auto-Connect Engine for OmniScreen
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

$global:StandaloneVirtualScreenWindow = $null

function Show-StandaloneVirtualScreen {
    param(
        [Parameter(Mandatory=$true)] [string]$ScrcpyPath,
        [Parameter(Mandatory=$true)] [string]$AdbPath,
        [int]$DesktopDpi = 200,
        [bool]$Fullscreen = $false,
        [bool]$ScreenOff = $false,
        [bool]$WindowsKeyIntercept = $true,
        [string]$AudioOutput = "Laptop",
        [string]$DeviceModel = "Samsung Galaxy S25 FE"
    )

    # Close any existing instance
    if ($global:StandaloneVirtualScreenWindow) {
        try { $global:StandaloneVirtualScreenWindow.Close() } catch { }
        $global:StandaloneVirtualScreenWindow = $null
    }

    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="OmniScreen — Virtual Desktop (Standalone Screen)"
        Height="620" Width="1020"
        WindowStartupLocation="CenterScreen"
        Background="#0B0F19"
        FontFamily="Segoe UI"
        Foreground="#F8FAFC">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="FontSize" Value="11"/>
            <Setter Property="Padding" Value="10,6"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}"
                                CornerRadius="6"
                                Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- TOP MONITOR BAR -->
        <Border Grid.Row="0" Background="#111827" BorderBrush="#1F2937" BorderThickness="0,0,0,1" Padding="16,10">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>

                <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                    <TextBlock Text="🖥️" FontSize="16" Margin="0,0,8,0" VerticalAlignment="Center"/>
                    <TextBlock Text="OmniScreen Virtual Screen" FontWeight="Bold" FontSize="13" Foreground="#38BDF8" VerticalAlignment="Center"/>
                    <Border Background="#1E293B" CornerRadius="4" Padding="6,2" Margin="10,0,0,0" VerticalAlignment="Center">
                        <TextBlock Text="1920×1080 @ 60Hz" FontSize="10" FontWeight="Bold" Foreground="#94A3B8"/>
                    </Border>
                    <Border x:Name="BadgeDpi" Background="#312E81" CornerRadius="4" Padding="6,2" Margin="6,0,0,0" VerticalAlignment="Center">
                        <TextBlock x:Name="TxtDpi" Text="${DesktopDpi} DPI" FontSize="10" FontWeight="Bold" Foreground="#A78BFA"/>
                    </Border>
                </StackPanel>

                <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                    <TextBlock x:Name="TxtClock" Text="--:--:--" Foreground="#64748B" FontSize="11" VerticalAlignment="Center" Margin="0,0,14,0"/>
                    <Button x:Name="BtnFullscreen" Content="🗗 Fullscreen" Background="#2563EB" Margin="0,0,8,0"/>
                    <Button x:Name="BtnClose" Content="✖" Background="#374151" Foreground="#9CA3AF" Padding="8,4"/>
                </StackPanel>
            </Grid>
        </Border>

        <!-- CENTRAL SCREEN CANVAS -->
        <Grid Grid.Row="1">
            <Border Background="#0B0F19">
                <Grid HorizontalAlignment="Center" VerticalAlignment="Center">
                    <StackPanel HorizontalAlignment="Center" VerticalAlignment="Center" Width="660">
                        <!-- Monitor Icon & Glow -->
                        <Border Width="76" Height="76" CornerRadius="38" Background="#1E1B4B" BorderBrush="#8B5CF6" BorderThickness="2"
                                HorizontalAlignment="Center" Margin="0,0,0,16">
                            <TextBlock Text="🖥️" FontSize="34" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>

                        <TextBlock Text="Standalone Virtual Screen Ready" FontSize="22" FontWeight="Bold" Foreground="#F8FAFC"
                                   HorizontalAlignment="Center" Margin="0,0,0,6"/>
                        <TextBlock Text="Independent 1080p landscape display active on your PC." FontSize="13" Foreground="#94A3B8"
                                   HorizontalAlignment="Center" Margin="0,0,0,22"/>

                        <!-- Auto-Detect Status Box -->
                        <Border x:Name="BoxAutoConnect" Background="#1E293B" CornerRadius="10" BorderBrush="#334155" BorderThickness="1" Padding="16,14" Margin="0,0,0,22">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="Auto"/>
                                    <ColumnDefinition Width="*"/>
                                </Grid.ColumnDefinitions>
                                <TextBlock x:Name="TxtIconStatus" Text="⚡" FontSize="22" Margin="0,0,12,0" VerticalAlignment="Center"/>
                                <StackPanel Grid.Column="1">
                                    <StackPanel Orientation="Horizontal" Margin="0,0,0,3">
                                        <TextBlock Text="Auto-Connect Daemon: " FontWeight="Bold" FontSize="12" Foreground="#38BDF8"/>
                                        <TextBlock x:Name="TxtAdbStatus" Text="Listening on USB ports..." FontSize="12" Foreground="#34D399"/>
                                    </StackPanel>
                                    <TextBlock x:Name="TxtAdbSubtext" Text="Connect your Samsung Galaxy phone via USB anytime — Samsung DeX will automatically open on this screen."
                                               FontSize="11" Foreground="#94A3B8" TextWrapping="Wrap"/>
                                </StackPanel>
                            </Grid>
                        </Border>

                        <!-- Quick Action Source Buttons -->
                        <UniformGrid Columns="3" Margin="0,0,0,8">
                            <Border Background="#1E293B" CornerRadius="8" BorderBrush="#059669" BorderThickness="1" Margin="0,0,6,0" Padding="12,10">
                                <StackPanel HorizontalAlignment="Center">
                                    <TextBlock Text="🎮 HDMI Capture Feed" Foreground="#34D399" FontSize="12" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,0,0,3"/>
                                    <TextBlock Text="PS4 / Switch / Chromecast" Foreground="#94A3B8" FontSize="10" HorizontalAlignment="Center" Margin="0,0,0,8"/>
                                    <Button x:Name="BtnActionCapture" Content="Switch to HDMI" Background="#059669" Padding="8,4" FontSize="10"/>
                                </StackPanel>
                            </Border>

                            <Border Background="#1E293B" CornerRadius="8" BorderBrush="#0284C7" BorderThickness="1" Margin="3,0,3,0" Padding="12,10">
                                <StackPanel HorizontalAlignment="Center">
                                    <TextBlock Text="🌐 Web Workspace" Foreground="#38BDF8" FontSize="12" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,0,0,3"/>
                                    <TextBlock Text="Secondary PC Browser" Foreground="#94A3B8" FontSize="10" HorizontalAlignment="Center" Margin="0,0,0,8"/>
                                    <Button x:Name="BtnActionWeb" Content="Open Workspace" Background="#0284C7" Padding="8,4" FontSize="10"/>
                                </StackPanel>
                            </Border>

                            <Border Background="#1E293B" CornerRadius="8" BorderBrush="#7C3AED" BorderThickness="1" Margin="6,0,0,0" Padding="12,10">
                                <StackPanel HorizontalAlignment="Center">
                                    <TextBlock Text="💻 Windows Extend" Foreground="#A78BFA" FontSize="12" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,0,0,3"/>
                                    <TextBlock Text="Project Desktop (Win + K)" Foreground="#94A3B8" FontSize="10" HorizontalAlignment="Center" Margin="0,0,0,8"/>
                                    <Button x:Name="BtnActionProject" Content="Open Cast (Win+K)" Background="#7C3AED" Padding="8,4" FontSize="10"/>
                                </StackPanel>
                            </Border>
                        </UniformGrid>
                    </StackPanel>
                </Grid>
            </Border>
        </Grid>

        <!-- FOOTER STATUS -->
        <Border Grid.Row="2" Background="#0F172A" BorderBrush="#1F2937" BorderThickness="0,1,0,0" Padding="16,6">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <TextBlock Text="OmniScreen Virtual Desktop Engine • Standalone Mode" FontSize="10" Foreground="#64748B" VerticalAlignment="Center"/>
                <TextBlock Grid.Column="1" Text="Press F11 for Fullscreen • Alt + Q to Exit" FontSize="10" Foreground="#64748B" VerticalAlignment="Center"/>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

    $reader = [System.Xml.XmlNodeReader]::new($xaml)
    $win = [System.Windows.Markup.XamlReader]::Load($reader)

    $txtClock = $win.FindName("TxtClock")
    $btnFullscreen = $win.FindName("BtnFullscreen")
    $btnClose = $win.FindName("BtnClose")
    $txtAdbStatus = $win.FindName("TxtAdbStatus")
    $txtAdbSubtext = $win.FindName("TxtAdbSubtext")
    $txtIconStatus = $win.FindName("TxtIconStatus")
    $boxAutoConnect = $win.FindName("BoxAutoConnect")

    $btnActionCapture = $win.FindName("BtnActionCapture")
    $btnActionWeb = $win.FindName("BtnActionWeb")
    $btnActionProject = $win.FindName("BtnActionProject")

    $global:StandaloneVirtualScreenWindow = $win

    # State tracking
    $script:isFullscreen = $false
    $script:prevRect = @{
        Left = $win.Left
        Top = $win.Top
        Width = $win.Width
        Height = $win.Height
        Style = $win.WindowStyle
        Resize = $win.ResizeMode
    }

    $ToggleFullscreen = {
        if ($script:isFullscreen) {
            $win.WindowStyle = [System.Windows.WindowStyle]::SingleBorderWindow
            $win.ResizeMode = [System.Windows.ResizeMode]::CanResize
            $win.WindowState = [System.Windows.WindowState]::Normal
            $btnFullscreen.Content = "🗗 Fullscreen"
            $script:isFullscreen = $false
        } else {
            $win.WindowStyle = [System.Windows.WindowStyle]::None
            $win.ResizeMode = [System.Windows.ResizeMode]::NoResize
            $win.WindowState = [System.Windows.WindowState]::Maximized
            $btnFullscreen.Content = "🗗 Windowed"
            $script:isFullscreen = $true
        }
    }

    if ($Fullscreen) {
        & $ToggleFullscreen
    }

    $btnFullscreen.Add_Click({ & $ToggleFullscreen })

    $btnClose.Add_Click({
        $win.Close()
    })

    # Keyboard hotkeys
    $win.Add_KeyDown({
        param($s, $e)
        if ($e.Key -eq [System.Windows.Input.Key]::F11) {
            & $ToggleFullscreen
            $e.Handled = $true
        } elseif ($e.Key -eq [System.Windows.Input.Key]::Escape) {
            if ($script:isFullscreen) {
                & $ToggleFullscreen
                $e.Handled = $true
            } else {
                $win.Close()
            }
        } elseif ($e.Key -eq [System.Windows.Input.Key]::Q -and ([System.Windows.Input.Keyboard]::Modifiers -band [System.Windows.Input.ModifierKeys]::Alt)) {
            $win.Close()
            $e.Handled = $true
        }
    })

    # Action 1: HDMI Capture Feed
    $btnActionCapture.Add_Click({
        $viewerHtml = Join-Path $PSScriptRoot "ConsoleViewer.html"
        Start-Process "msedge.exe" -ArgumentList "--app=""file:///$viewerHtml"" --start-fullscreen"
    })

    # Action 2: Secondary PC Workspace
    $btnActionWeb.Add_Click({
        Start-Process "msedge.exe" -ArgumentList "--new-window --start-maximized"
    })

    # Action 3: Windows Cast / Project (Win + K)
    $btnActionProject.Add_Click({
        try {
            Start-Process "explorer.exe" "ms-settings-connectabledevices:devicediscovery"
        } catch { }
    })

    # Background USB Auto-Detector & Clock Timer
    $detectorTimer = [System.Windows.Threading.DispatcherTimer]::new()
    $detectorTimer.Interval = [TimeSpan]::FromMilliseconds(1500)

    $script:isLaunchingDex = $false

    $detectorTimer.Add_Tick({
        $txtClock.Text = (Get-Date -Format 'HH:mm:ss')

        if ($script:isLaunchingDex) { return }

        $phone = Get-ConnectedPhoneInfo -AdbPath $AdbPath
        if ($phone.Status -eq "Connected") {
            $script:isLaunchingDex = $true
            $txtAdbStatus.Text = "Connected: $($phone.FriendlyName)!"
            $txtAdbStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#34D399")
            $txtAdbSubtext.Text = "Launching Samsung DeX on virtual display..."
            $txtIconStatus.Text = "🚀"

            # Launch DeX virtual display stream
            Start-Sleep -Milliseconds 300
            $proc = Start-OmniScreenSession -ScrcpyPath $ScrcpyPath `
                                            -AdbPath $AdbPath `
                                            -Mode "VirtualDesktop" `
                                            -Fullscreen $script:isFullscreen `
                                            -ScreenOff $ScreenOff `
                                            -WindowsKeyIntercept $WindowsKeyIntercept `
                                            -AudioOutput $AudioOutput `
                                            -DeviceModel $phone.FriendlyName `
                                            -DesktopDpi $DesktopDpi `
                                            -SkipStandaloneFallback $true

            if ($proc -and -not $proc.HasExited) {
                # Minimize / hide standalone screen while DeX is active
                $win.WindowState = [System.Windows.WindowState]::Minimized
            } else {
                $script:isLaunchingDex = $false
                $txtAdbStatus.Text = "DeX session ended. Listening on USB..."
                $txtAdbStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FBBF24")
                $txtIconStatus.Text = "⚡"
            }
        } else {
            $txtAdbStatus.Text = "Listening on USB ports..."
            $txtAdbStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#34D399")
            $txtIconStatus.Text = "⚡"
        }
    })

    $win.Add_Closed({
        $detectorTimer.Stop()
        $global:StandaloneVirtualScreenWindow = $null
    })

    $detectorTimer.Start()
    $win.Show()

    return $win
}
