#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Launcher template — starts VS Code and sets custom AppUserModelID + icon on the window.
.DESCRIPTION
    This is a reusable template. The setup script copies it alongside the icon
    and fills in RepoPath, AppId, and IconPath defaults.
    
    The agent should embed this logic directly into the generated setup script's
    launcher output section, substituting the three parameters defaults.
#>
param(
    [string]$RepoPath,
    [string]$AppId,
    [string]$IconPath
)

$ErrorActionPreference = 'Stop'

if (-not $RepoPath -or -not (Test-Path $RepoPath)) {
    Write-Error "Repo path not found: $RepoPath"
    exit 1
}

# --- C# interop for window-level AppUserModelID and icon ---
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public static class WindowAppId
{
    [DllImport("shell32.dll")]
    static extern int SHGetPropertyStoreForWindow(
        IntPtr hwnd,
        [In] ref Guid riid,
        [Out, MarshalAs(UnmanagedType.Interface)] out IPropertyStore ppv);

    [DllImport("user32.dll", SetLastError = true)]
    static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);

    [DllImport("user32.dll")]
    static extern IntPtr LoadImage(IntPtr hInst, string lpszName, uint uType, int cx, int cy, uint fuLoad);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    static extern bool IsWindow(IntPtr hWnd);

    [ComImport, InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    [Guid("886d8eeb-8cf2-4446-8d02-cdba1dbdcf99")]
    public interface IPropertyStore
    {
        [PreserveSig] int GetCount(out uint cProps);
        [PreserveSig] int GetAt(uint iProp, out PropertyKey pkey);
        [PreserveSig] int GetValue(ref PropertyKey key, out PropVariant pv);
        [PreserveSig] int SetValue(ref PropertyKey key, ref PropVariant pv);
        [PreserveSig] int Commit();
    }

    [StructLayout(LayoutKind.Sequential, Pack = 4)]
    public struct PropertyKey
    {
        public Guid fmtid;
        public uint pid;
    }

    [StructLayout(LayoutKind.Explicit, Size = 24)]
    public struct PropVariant
    {
        [FieldOffset(0)] public ushort vt;
        [FieldOffset(8)] public IntPtr p;
    }

    public static bool SetAppId(IntPtr hwnd, string appId)
    {
        if (!IsWindow(hwnd)) return false;

        var iid = new Guid("886d8eeb-8cf2-4446-8d02-cdba1dbdcf99");
        IPropertyStore store;
        int hr = SHGetPropertyStoreForWindow(hwnd, ref iid, out store);
        if (hr != 0) return false;

        var key = new PropertyKey
        {
            fmtid = new Guid("9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3"),
            pid = 5
        };
        var pv = new PropVariant { vt = 31, p = Marshal.StringToCoTaskMemUni(appId) };

        hr = store.SetValue(ref key, ref pv);
        store.Commit();

        Marshal.FreeCoTaskMem(pv.p);
        Marshal.ReleaseComObject(store);
        return hr == 0;
    }

    public static bool SetIcon(IntPtr hwnd, string iconPath)
    {
        if (!IsWindow(hwnd)) return false;

        IntPtr bigIcon = LoadImage(IntPtr.Zero, iconPath, 1, 32, 32, 0x10);
        IntPtr smallIcon = LoadImage(IntPtr.Zero, iconPath, 1, 16, 16, 0x10);

        if (bigIcon != IntPtr.Zero)
            SendMessage(hwnd, 0x0080, (IntPtr)1, bigIcon);
        if (smallIcon != IntPtr.Zero)
            SendMessage(hwnd, 0x0080, (IntPtr)0, smallIcon);

        return bigIcon != IntPtr.Zero;
    }
}
"@

# --- Launch VS Code ---
code $RepoPath

# --- Find the window and apply AppUserModelID + icon ---
$repoLeaf = Split-Path $RepoPath -Leaf
$maxWait = 30
$found = $false

for ($i = 0; $i -lt $maxWait; $i++) {
    Start-Sleep -Seconds 1

    $windows = Get-Process -Name 'Code' -ErrorAction SilentlyContinue |
        Where-Object { $_.MainWindowHandle -ne [IntPtr]::Zero } |
        Where-Object { $_.MainWindowTitle -match [regex]::Escape($repoLeaf) }

    foreach ($proc in $windows) {
        $hwnd = $proc.MainWindowHandle
        if ($hwnd -eq [IntPtr]::Zero) { continue }

        $ok = [WindowAppId]::SetAppId($hwnd, $AppId)
        if ($ok) {
            if ($IconPath -and (Test-Path $IconPath)) {
                [WindowAppId]::SetIcon($hwnd, $IconPath)
            }
            $found = $true
            break
        }
    }
    if ($found) { break }
}

exit 0
