#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Creates a taskbar-pinnable shortcut with a retro green terminal VS Code icon.
.DESCRIPTION
    Generates a custom 80's phosphor-green terminal .ico file and creates a Desktop
    shortcut with a custom AppUserModelID for separate taskbar grouping.

    The icon is a >_ terminal prompt in phosphor green on a dark background with
    CRT scan lines — clearly code-related but distinctly retro.
.EXAMPLE
    ./setup-taskbar.ps1
.EXAMPLE
    ./setup-taskbar.ps1 -ShortcutName "My Skills"
#>
param(
    [string]$ShortcutName = 'Personal Skills'
)

$ErrorActionPreference = 'Stop'

# --- Validate context ---
$repoPath = git rev-parse --show-toplevel 2>$null
if (-not $repoPath) { Write-Error "Not in a git repo."; exit 1 }
$repoPath = $repoPath.Replace('/', '\')

$assetsDir = Join-Path $HOME '.agents' 'assets'
$iconPath  = Join-Path $assetsDir 'personal-skills.ico'
$launcherScript = Join-Path $PSScriptRoot 'launch-skills.ps1'
$shortcutPath = Join-Path ([Environment]::GetFolderPath('Desktop')) "$ShortcutName.lnk"
$appId = 'Daweins.PersonalSkills.VSCode'

# ============================================================
# Icon generation — retro green terminal >_ prompt
# ============================================================
Add-Type -AssemblyName System.Drawing

function New-RetroIcon([int]$Size) {
    $bmp = New-Object System.Drawing.Bitmap $Size, $Size
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $s = $Size / 256.0

    # Dark background
    $g.Clear([System.Drawing.Color]::FromArgb(255, 13, 17, 23))

    $green     = [System.Drawing.Color]::FromArgb(255, 0, 255, 65)   # #00FF41
    $glowGreen = [System.Drawing.Color]::FromArgb(40, 0, 255, 65)
    $dimGreen  = [System.Drawing.Color]::FromArgb(60, 0, 255, 65)

    # Thin border (CRT bezel)
    $borderWidth = [Math]::Max(1, [int](3 * $s))
    $borderPen = New-Object System.Drawing.Pen $dimGreen, $borderWidth
    $m = [int](8 * $s)
    $g.DrawRectangle($borderPen, $m, $m, ($Size - 2 * $m - 1), ($Size - 2 * $m - 1))

    # Glow layer (wider, semi-transparent — drawn first behind main strokes)
    $glowWidth = [Math]::Max(3, [int](30 * $s))
    $glowPen = New-Object System.Drawing.Pen $glowGreen, $glowWidth
    $glowPen.StartCap = $glowPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round

    # > chevron glow
    $g.DrawLine($glowPen, (55*$s), (65*$s), (145*$s), (128*$s))
    $g.DrawLine($glowPen, (145*$s), (128*$s), (55*$s), (191*$s))
    # _ cursor glow
    $g.DrawLine($glowPen, (160*$s), (191*$s), (215*$s), (191*$s))

    # Main >_ strokes
    $mainWidth = [Math]::Max(2, [int](20 * $s))
    $mainPen = New-Object System.Drawing.Pen $green, $mainWidth
    $mainPen.StartCap = $mainPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round

    # > chevron
    $g.DrawLine($mainPen, (55*$s), (65*$s), (145*$s), (128*$s))
    $g.DrawLine($mainPen, (145*$s), (128*$s), (55*$s), (191*$s))
    # _ cursor
    $g.DrawLine($mainPen, (160*$s), (191*$s), (215*$s), (191*$s))

    # CRT scan lines
    $scanPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(20, 0, 0, 0)), 1
    $step = [Math]::Max(2, [int](4 * $s))
    for ($y = 0; $y -lt $Size; $y += $step) {
        $g.DrawLine($scanPen, 0, $y, $Size, $y)
    }

    $g.Dispose()
    foreach ($p in @($borderPen, $glowPen, $mainPen, $scanPen)) { $p.Dispose() }
    return $bmp
}

Write-Host "Generating icon..." -ForegroundColor Cyan
$sizes = @(256, 48, 32, 16)
$pngList = @()
foreach ($sz in $sizes) {
    $bmp = New-RetroIcon $sz
    $ms  = New-Object System.IO.MemoryStream
    $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $pngList += ,@{ Size = $sz; Data = $ms.ToArray() }
    $bmp.Dispose(); $ms.Dispose()
}

# Write multi-size ICO
if (-not (Test-Path $assetsDir)) { New-Item -ItemType Directory -Path $assetsDir -Force | Out-Null }

$ico = New-Object System.IO.MemoryStream
$w   = New-Object System.IO.BinaryWriter $ico

# ICONDIR header
$w.Write([uint16]0)                  # Reserved
$w.Write([uint16]1)                  # Type = ICO
$w.Write([uint16]$pngList.Count)     # Image count

# ICONDIRENTRY for each size (calculate data offsets)
$dataOffset = 6 + (16 * $pngList.Count)
foreach ($entry in $pngList) {
    $dim = if ($entry.Size -ge 256) { [byte]0 } else { [byte]$entry.Size }
    $w.Write($dim)                           # Width
    $w.Write($dim)                           # Height
    $w.Write([byte]0)                        # Color count
    $w.Write([byte]0)                        # Reserved
    $w.Write([uint16]1)                      # Planes
    $w.Write([uint16]32)                     # Bits per pixel
    $w.Write([uint32]$entry.Data.Length)      # Data size
    $w.Write([uint32]$dataOffset)            # Data offset
    $dataOffset += $entry.Data.Length
}

# PNG image data
foreach ($entry in $pngList) { $w.Write($entry.Data) }
$w.Flush()

[System.IO.File]::WriteAllBytes($iconPath, $ico.ToArray())
$w.Dispose(); $ico.Dispose()
Write-Host "  Icon saved: $iconPath" -ForegroundColor Green

# ============================================================
# Save launcher config
# ============================================================
$launcherConfig = Join-Path $assetsDir 'launcher-config.json'
@{ repoPath = $repoPath } | ConvertTo-Json | Set-Content $launcherConfig -Encoding UTF8

# ============================================================
# Create Desktop shortcut — launches via launcher script
# ============================================================
Write-Host "Creating shortcut..." -ForegroundColor Cyan

$pwshExe = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
if (-not $pwshExe) { $pwshExe = (Get-Command powershell).Source }

$shell = New-Object -ComObject WScript.Shell
$lnk = $shell.CreateShortcut($shortcutPath)
$lnk.TargetPath       = $pwshExe
$lnk.Arguments         = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$launcherScript`""
$lnk.IconLocation      = "$iconPath, 0"
$lnk.Description       = "$ShortcutName - VS Code"
$lnk.WorkingDirectory  = $repoPath
$lnk.WindowStyle       = 7  # Minimized (hides the PowerShell window)
$lnk.Save()
Write-Host "  Shortcut: $shortcutPath" -ForegroundColor Green

# ============================================================
# Set AppUserModelID on the shortcut for separate taskbar grouping
# ============================================================
Write-Host "Setting AppUserModelID..." -ForegroundColor Cyan

try {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public static class ShortcutAppId
{
    [DllImport("shell32.dll", SetLastError = true)]
    static extern int SHGetPropertyStoreFromParsingName(
        [MarshalAs(UnmanagedType.LPWStr)] string pszPath,
        IntPtr pbc,
        uint flags,
        [In] ref Guid riid,
        [Out, MarshalAs(UnmanagedType.Interface)] out IPropertyStore ppv);

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

    public static void Set(string lnkPath, string id)
    {
        var iid = new Guid("886d8eeb-8cf2-4446-8d02-cdba1dbdcf99");
        IPropertyStore store;
        int hr = SHGetPropertyStoreFromParsingName(lnkPath, IntPtr.Zero, 2u, ref iid, out store);
        Marshal.ThrowExceptionForHR(hr);

        var key = new PropertyKey
        {
            fmtid = new Guid("9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3"),
            pid = 5
        };
        var pv = new PropVariant { vt = 31, p = Marshal.StringToCoTaskMemUni(id) };

        hr = store.SetValue(ref key, ref pv);
        Marshal.ThrowExceptionForHR(hr);
        hr = store.Commit();
        Marshal.ThrowExceptionForHR(hr);

        Marshal.FreeCoTaskMem(pv.p);
        Marshal.ReleaseComObject(store);
    }
}
"@

    [ShortcutAppId]::Set($shortcutPath, $appId)
    Write-Host "  AppUserModelID: $appId" -ForegroundColor Green
}
catch {
    Write-Host "  Could not set AppUserModelID: $_" -ForegroundColor Yellow
    Write-Host "  The shortcut will still work but may group with other VS Code windows." -ForegroundColor Yellow
}

# ============================================================
# Done
# ============================================================
Write-Host ""
Write-Host "Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Right-click 'Personal Skills' on your Desktop" -ForegroundColor White
Write-Host "  2. Choose 'Pin to taskbar'" -ForegroundColor White
Write-Host "  3. Launch from the pinned icon — it will appear as its own taskbar group" -ForegroundColor White
