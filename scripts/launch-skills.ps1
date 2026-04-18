#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Launches VS Code for the personal-skills repo with a custom AppUserModelID
    so it appears as a separate taskbar group.
.DESCRIPTION
    1. Starts VS Code with the configured repo path
    2. Finds the new VS Code window by title
    3. Sets AppUserModelID on the window handle via SHGetPropertyStoreForWindow
    4. Optionally sets the window icon from the generated .ico file
#>
param(
    [string]$RepoPath,
    [string]$AppId = 'Daweins.PersonalSkills.VSCode'
)

$ErrorActionPreference = 'Stop'

# --- Resolve repo path ---
if (-not $RepoPath) {
    # Try to read from a saved config
    $configFile = Join-Path $HOME '.agents' 'assets' 'launcher-config.json'
    if (Test-Path $configFile) {
        $config = Get-Content $configFile -Raw | ConvertFrom-Json
        $RepoPath = $config.repoPath
    }
}
if (-not $RepoPath -or -not (Test-Path $RepoPath)) {
    Write-Error "Repo path not found. Run setup-taskbar.ps1 first."
    exit 1
}

$iconPath = Join-Path $HOME '.agents' 'assets' 'personal-skills.ico'

# --- Add the C# helper for window AppUserModelID ---
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

        // LR_LOADFROMFILE = 0x10
        IntPtr bigIcon = LoadImage(IntPtr.Zero, iconPath, 1, 32, 32, 0x10);
        IntPtr smallIcon = LoadImage(IntPtr.Zero, iconPath, 1, 16, 16, 0x10);

        if (bigIcon != IntPtr.Zero)
            SendMessage(hwnd, 0x0080 /* WM_SETICON */, (IntPtr)1 /* ICON_BIG */, bigIcon);
        if (smallIcon != IntPtr.Zero)
            SendMessage(hwnd, 0x0080 /* WM_SETICON */, (IntPtr)0 /* ICON_SMALL */, smallIcon);

        return bigIcon != IntPtr.Zero;
    }
}
"@

# --- Get existing VS Code windows before launch ---
$beforePids = @(Get-Process -Name 'Code' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Id)

# --- Launch VS Code ---
code $RepoPath

# --- Wait for the new window to appear ---
$repoLeaf = Split-Path $RepoPath -Leaf
$maxWait = 30
$found = $false

for ($i = 0; $i -lt $maxWait; $i++) {
    Start-Sleep -Seconds 1

    # Find VS Code windows whose title contains the repo name
    $windows = Get-Process -Name 'Code' -ErrorAction SilentlyContinue |
        Where-Object { $_.MainWindowHandle -ne [IntPtr]::Zero } |
        Where-Object { $_.MainWindowTitle -match [regex]::Escape($repoLeaf) }

    foreach ($proc in $windows) {
        $hwnd = $proc.MainWindowHandle
        if ($hwnd -eq [IntPtr]::Zero) { continue }

        $ok = [WindowAppId]::SetAppId($hwnd, $AppId)
        if ($ok) {
            if (Test-Path $iconPath) {
                [WindowAppId]::SetIcon($hwnd, $iconPath)
            }
            $found = $true
            break
        }
    }
    if ($found) { break }
}

if ($found) {
    # Minimal output — this runs from a shortcut
    exit 0
} else {
    # VS Code opened but we couldn't find/modify the window — not fatal
    exit 0
}
