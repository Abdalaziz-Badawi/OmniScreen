Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# Win32 Keybd_event definition for reliable F11 injection
$pinvoke = @"
using System;
using System.Runtime.InteropServices;
public class KeyInput {
    [DllImport("user32.dll")]
    public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);
    
    public static void SendF11() {
        const byte VK_F11 = 0x7A;
        keybd_event(VK_F11, 0, 0, UIntPtr.Zero);
        keybd_event(VK_F11, 0, 2, UIntPtr.Zero);
    }
}
"@
if (-not ([System.Management.Automation.PSTypeName]'KeyInput').Type) {
    Add-Type -TypeDefinition $pinvoke
}

function Show-FullscreenToggleButton {
    param(
        [Parameter(Mandatory=$true)] $ScrcpyProcess
    )

    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="OmniScreen Fullscreen Toggle"
        WindowStyle="None"
        AllowsTransparency="True"
        Background="Transparent"
        Topmost="True"
        ShowInTaskbar="False"
        ResizeMode="NoResize"
        Height="42" Width="42"
        FontFamily="Segoe UI">
    <Grid>
        <!-- Retractable Floating Button -->
        <Border x:Name="ToggleBtn"
                Width="36" Height="36"
                CornerRadius="18"
                Background="#2563EB"
                BorderBrush="#38BDF8"
                BorderThickness="1.5"
                Cursor="Hand"
                Opacity="0.25"
                ToolTip="Click to Enter / Exit Fullscreen (F11)">
            <Border.Effect>
                <DropShadowEffect Color="#000000" BlurRadius="6" ShadowDepth="2" Opacity="0.4"/>
            </Border.Effect>
            <TextBlock x:Name="TxtIcon" Text="🗗" FontSize="16" Foreground="White"
                       HorizontalAlignment="Center" VerticalAlignment="Center" Margin="0,-1,0,0"/>
        </Border>
    </Grid>
</Window>
"@

    $reader = [System.Xml.XmlNodeReader]::new($xaml)
    $toggleWin = [System.Windows.Markup.XamlReader]::Load($reader)

    # Position at Top-Right of Primary Screen
    $screen = [System.Windows.Forms.Screen]::PrimaryScreen
    $toggleWin.Left = $screen.Bounds.Width - 60
    $toggleWin.Top = 16

    $btn = $toggleWin.FindName("ToggleBtn")
    $txtIcon = $toggleWin.FindName("TxtIcon")

    # Retractable hover effects: expands and brightens on hover, retracts to transparent on leave
    $btn.Add_MouseEnter({
        $btn.Opacity = 1.0
        $btn.Width = 38
        $btn.Height = 38
    })
    $btn.Add_MouseLeave({
        $btn.Opacity = 0.25
        $btn.Width = 36
        $btn.Height = 36
    })

    # Drag to reposition anywhere if preferred
    $btn.Add_MouseLeftButtonDown({
        $toggleWin.DragMove()
    })

    # Click to toggle Fullscreen (sends F11 directly to active session)
    $btn.Add_MouseLeftButtonUp({
        [KeyInput]::SendF11()
    })

    # Auto close when scrcpy exits
    $timer = [System.Windows.Threading.DispatcherTimer]::new()
    $timer.Interval = [TimeSpan]::FromMilliseconds(500)
    $timer.Add_Tick({
        if (-not $ScrcpyProcess -or $ScrcpyProcess.HasExited) {
            $timer.Stop()
            $toggleWin.Close()
        }
    })
    $timer.Start()

    $toggleWin.Show()
}
