Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# Load KeyboardHook & Window helper class
$hookPath = Join-Path $PSScriptRoot "KeyboardHook.cs"
if (-not ([System.Management.Automation.PSTypeName]'OmniScreen.KeyboardHook').Type) {
    Add-Type -Path $hookPath
}

function Show-FullscreenToggleButton {
    param(
        [Parameter(Mandatory=$true)] [System.Diagnostics.Process]$ScrcpyProcess,
        [IntPtr]$ScrcpyHwnd = [IntPtr]::Zero
    )

    $targetPid = $ScrcpyProcess.Id

    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="OmniScreen Fullscreen Controller"
        WindowStyle="None"
        AllowsTransparency="True"
        Background="Transparent"
        Topmost="True"
        ShowInTaskbar="False"
        ResizeMode="NoResize"
        Height="42" Width="170"
        FontFamily="Segoe UI">
    <Window.Resources>
        <Style TargetType="ToolTip">
            <Setter Property="Background" Value="#0F172A"/>
            <Setter Property="Foreground" Value="#F8FAFC"/>
            <Setter Property="BorderBrush" Value="#38BDF8"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="FontSize" Value="11"/>
        </Style>
    </Window.Resources>
    <Grid>
        <!-- Retractable Floating Pill Widget -->
        <Border x:Name="ToggleBtn"
                Height="36"
                CornerRadius="18"
                Background="#0F172A"
                BorderBrush="#38BDF8"
                BorderThickness="1.5"
                Cursor="Hand"
                Opacity="0.80"
                Margin="2"
                ToolTip="Click to toggle Fullscreen / Windowed (or press F11). Drag to reposition.">
            <Border.Effect>
                <DropShadowEffect Color="#000000" BlurRadius="8" ShadowDepth="2" Opacity="0.5"/>
            </Border.Effect>
            
            <Grid Margin="10,0,10,0">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>

                <TextBlock x:Name="TxtIcon" Grid.Column="0" Text="🗗" FontSize="14" Foreground="#38BDF8"
                           VerticalAlignment="Center" Margin="0,0,6,0"/>

                <TextBlock x:Name="TxtLabel" Grid.Column="1" Text="Fullscreen" FontSize="12" FontWeight="SemiBold"
                           Foreground="#F8FAFC" VerticalAlignment="Center"/>

                <!-- Hotkey indicator badge -->
                <Border Grid.Column="2" Background="#1E293B" CornerRadius="4" Padding="4,1" Margin="6,0,0,0" VerticalAlignment="Center">
                    <TextBlock Text="F11" FontSize="10" FontWeight="Bold" Foreground="#94A3B8"/>
                </Border>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

    $reader = [System.Xml.XmlNodeReader]::new($xaml)
    $toggleWin = [System.Windows.Markup.XamlReader]::Load($reader)

    # Position at Top-Right of Primary Screen with clean margin
    $screen = [System.Windows.Forms.Screen]::PrimaryScreen
    $toggleWin.Left = $screen.Bounds.Width - 190
    $toggleWin.Top = 14

    $btn = $toggleWin.FindName("ToggleBtn")
    $txtIcon = $toggleWin.FindName("TxtIcon")
    $txtLabel = $toggleWin.FindName("TxtLabel")

    # Retractable hover effects: brightens and expands slightly on hover
    $btn.Add_MouseEnter({
        $btn.Opacity = 1.0
        $btn.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#60A5FA")
    })
    $btn.Add_MouseLeave({
        $btn.Opacity = 0.80
        $btn.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#38BDF8")
    })

    # Drag to reposition anywhere if preferred
    $btn.Add_MouseLeftButtonDown({
        try { $toggleWin.DragMove() } catch { }
    })

    # Track fullscreen state for label toggling
    $isFs = $true
    $clickAction = {
        $isFs = -not $isFs
        if ($isFs) {
            $txtIcon.Text = "🗗"
            $txtLabel.Text = "Fullscreen"
        } else {
            $txtIcon.Text = "🗖"
            $txtLabel.Text = "Windowed"
        }

        # Resolve scrcpy hwnd dynamically
        $hwndTarget = [IntPtr]::Zero
        try {
            $p = [System.Diagnostics.Process]::GetProcessById($targetPid)
            $p.Refresh()
            $hwndTarget = $p.MainWindowHandle
        } catch { }

        # Toggle fullscreen reliably via Win32 F11 injection
        [OmniScreen.KeyboardHook]::ToggleFullscreen($hwndTarget)
    }.GetNewClosure()

    $btn.Add_MouseLeftButtonUp($clickAction)

    # On Show: Apply Win32 WS_EX_NOACTIVATE & HWND_TOPMOST so clicks never steal focus
    $toggleWin.Add_Loaded({
        try {
            $helper = [System.Windows.Interop.WindowInteropHelper]::new($toggleWin)
            [OmniScreen.KeyboardHook]::MakeTopmostAndNoActivate($helper.Handle)
        } catch { }
    })

    # Keep Topmost & auto-close watchdog timer (with closure over $targetPid)
    $timer = [System.Windows.Threading.DispatcherTimer]::new()
    $timer.Interval = [TimeSpan]::FromMilliseconds(1000)

    $watchdogAction = {
        $alive = $false
        try {
            $p = [System.Diagnostics.Process]::GetProcessById($targetPid)
            if (-not $p.HasExited) { $alive = $true }
        } catch { }

        # If scrcpy closed, close toggle window
        if (-not $alive) {
            $timer.Stop()
            try { $toggleWin.Close() } catch { }
            return
        }

        # Periodically ensure widget stays above scrcpy surface
        try {
            $helper = [System.Windows.Interop.WindowInteropHelper]::new($toggleWin)
            [OmniScreen.KeyboardHook]::RefreshTopmost($helper.Handle)
        } catch { }
    }.GetNewClosure()

    $timer.Add_Tick($watchdogAction)
    $timer.Start()

    $toggleWin.Show()
    return $toggleWin
}
