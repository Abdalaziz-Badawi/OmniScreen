Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

function Show-FloatingTopBar {
    param(
        [Parameter(Mandatory=$true)] $ScrcpyProcess,
        [Parameter(Mandatory=$true)] $AdbPath
    )

    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="OmniScreen Toolbar"
        WindowStyle="None"
        AllowsTransparency="True"
        Background="Transparent"
        Topmost="True"
        ShowInTaskbar="False"
        ResizeMode="NoResize"
        Height="54" Width="510"
        FontFamily="Segoe UI">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Padding" Value="9,6"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Foreground" Value="#F8FAFC"/>
            <Setter Property="Background" Value="#334155"/>
            <Setter Property="Margin" Value="2,0"/>
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
        <!-- The Floating Capsule Pill -->
        <Border x:Name="PillContainer"
                Background="#1E293BE6"
                BorderBrush="#38BDF8"
                BorderThickness="1"
                CornerRadius="0,0,16,16"
                Padding="12,6"
                HorizontalAlignment="Center"
                VerticalAlignment="Top"
                Opacity="0.25">
            <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                <Button x:Name="BtnExitFullscreen" Content="🗗 Windowed" Background="#2563EB" ToolTip="Restore standard window with [X] button"/>
                <Button x:Name="BtnRecentApps" Content="📱 Recent Apps" Background="#475569" ToolTip="View currently open background apps"/>
                <Button x:Name="BtnHome" Content="🏠 Home" Background="#475569" ToolTip="Go to Home Screen"/>
                <Button x:Name="BtnBack" Content="🔙 Back" Background="#475569" ToolTip="Back"/>
                <Button x:Name="BtnSound" Content="🔊 Sound" Background="#0D9488" ToolTip="Open Phone Media Output &amp; Sound Settings"/>
                <Button x:Name="BtnClose" Content="✖ Close" Background="#DC2626" ToolTip="Exit session completely"/>
            </StackPanel>
        </Border>
    </Grid>
</Window>
"@

    $reader = [System.Xml.XmlNodeReader]::new($xaml)
    $bar = [System.Windows.Markup.XamlReader]::Load($reader)

    # Position at top center
    $screen = [System.Windows.Forms.Screen]::PrimaryScreen
    $bar.Left = ($screen.Bounds.Width - 510) / 2
    $bar.Top = 0

    $pill = $bar.FindName("PillContainer")
    $btnExitFullscreen = $bar.FindName("BtnExitFullscreen")
    $btnRecentApps = $bar.FindName("BtnRecentApps")
    $btnHome = $bar.FindName("BtnHome")
    $btnBack = $bar.FindName("BtnBack")
    $btnSound = $bar.FindName("BtnSound")
    $btnClose = $bar.FindName("BtnClose")

    # Hover animations
    $bar.Add_MouseEnter({
        $pill.Opacity = 1.0
        $pill.Height = 44
    })
    $bar.Add_MouseLeave({
        $pill.Opacity = 0.25
    })

    # C# SendKeys helper for F11
    $btnExitFullscreen.Add_Click({
        [System.Windows.Forms.SendKeys]::SendWait("{F11}")
    })

    # Recent Apps click
    $btnRecentApps.Add_Click({
        Start-Process -FilePath $AdbPath -ArgumentList "shell input keyevent 187" -NoNewWindow
    })

    # Home click
    $btnHome.Add_Click({
        Start-Process -FilePath $AdbPath -ArgumentList "shell input keyevent 3" -NoNewWindow
    })

    # Back click
    $btnBack.Add_Click({
        Start-Process -FilePath $AdbPath -ArgumentList "shell input keyevent 4" -NoNewWindow
    })

    # Sound Settings / Media Output click
    $btnSound.Add_Click({
        # Opens Android sound panel & Samsung Media Output
        Start-Process -FilePath $AdbPath -ArgumentList "shell am start -a android.settings.SOUND_SETTINGS" -NoNewWindow
    })

    # Close click
    $btnClose.Add_Click({
        try {
            if ($ScrcpyProcess -and -not $ScrcpyProcess.HasExited) {
                $ScrcpyProcess.Kill()
            }
        } catch { }
        $bar.Close()
    })

    # Auto close when scrcpy exits
    $checkTimer = [System.Windows.Threading.DispatcherTimer]::new()
    $checkTimer.Interval = [TimeSpan]::FromMilliseconds(500)
    $checkTimer.Add_Tick({
        if (-not $ScrcpyProcess -or $ScrcpyProcess.HasExited) {
            $checkTimer.Stop()
            $bar.Close()
        }
    })
    $checkTimer.Start()

    $bar.Show()
}
