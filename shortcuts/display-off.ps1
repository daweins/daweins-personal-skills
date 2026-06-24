# Turns off all displays (internal + external).
# Move the mouse or press a key to wake them.
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Display {
    [DllImport("user32.dll")]
    public static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
}
"@
Start-Sleep -Milliseconds 500   # let your keypress release so the screen doesn't wake instantly
$HWND_BROADCAST = [IntPtr]0xffff
$WM_SYSCOMMAND  = 0x0112
$SC_MONITORPOWER = [IntPtr]0xF170
$MONITOR_OFF    = [IntPtr]2
[Display]::SendMessage($HWND_BROADCAST, $WM_SYSCOMMAND, $SC_MONITORPOWER, $MONITOR_OFF) | Out-Null
