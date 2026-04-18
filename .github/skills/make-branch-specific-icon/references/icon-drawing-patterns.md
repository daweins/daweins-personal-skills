# Icon Drawing Patterns — System.Drawing Reference

Techniques for generating custom `.ico` files in PowerShell using `System.Drawing`.
The agent should use these patterns when generating the `New-Icon` function.

## Setup

```powershell
Add-Type -AssemblyName System.Drawing

function New-Icon([int]$Size) {
    $bmp = New-Object System.Drawing.Bitmap $Size, $Size
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $s = $Size / 256.0   # Scale factor — design at 256, scale to any size

    # --- Draw here ---

    $g.Dispose()
    return $bmp
}
```

Always design coordinates at 256x256 and multiply by `$s` for scaling.

## Colors

```powershell
# Solid color
$color = [System.Drawing.Color]::FromArgb(255, 0, 255, 65)

# Semi-transparent (for glow effects)
$glow = [System.Drawing.Color]::FromArgb(40, 0, 255, 65)

# From hex
$color = [System.Drawing.ColorTranslator]::FromHtml('#FF6B35')
```

## HSL to Hex (for computed colors)

```powershell
function Convert-HslToHex([int]$H, [double]$S, [double]$L) {
    $C = (1 - [Math]::Abs(2 * $L - 1)) * $S
    $X = $C * (1 - [Math]::Abs(($H / 60.0) % 2 - 1))
    $M = $L - $C / 2
    if     ($H -lt 60)  { $R1=$C; $G1=$X; $B1=0 }
    elseif ($H -lt 120) { $R1=$X; $G1=$C; $B1=0 }
    elseif ($H -lt 180) { $R1=0;  $G1=$C; $B1=$X }
    elseif ($H -lt 240) { $R1=0;  $G1=$X; $B1=$C }
    elseif ($H -lt 300) { $R1=$X; $G1=0;  $B1=$C }
    else                { $R1=$C; $G1=0;  $B1=$X }
    $R = [int](($R1 + $M) * 255); $G = [int](($G1 + $M) * 255); $B = [int](($B1 + $M) * 255)
    return "#{0:x2}{1:x2}{2:x2}" -f $R, $G, $B
}
```

## Drawing Primitives

### Lines (for symbols like `>_`, `/`, `\`, `|`)

```powershell
$pen = New-Object System.Drawing.Pen $color, ([Math]::Max(2, [int](20 * $s)))
$pen.StartCap = $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
$g.DrawLine($pen, (x1*$s), (y1*$s), (x2*$s), (y2*$s))
```

### Text / Letters

```powershell
$font = New-Object System.Drawing.Font('Consolas', (140 * $s), [System.Drawing.FontStyle]::Bold)
$brush = New-Object System.Drawing.SolidBrush $color
$sf = New-Object System.Drawing.StringFormat
$sf.Alignment = $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
$g.DrawString('A', $font, $brush, (128*$s), (128*$s), $sf)
```

### Filled shapes

```powershell
# Circle
$brush = New-Object System.Drawing.SolidBrush $color
$g.FillEllipse($brush, (40*$s), (40*$s), (176*$s), (176*$s))

# Rounded rectangle
$path = New-Object System.Drawing.Drawing2D.GraphicsPath
$r = 20 * $s
$rect = New-Object System.Drawing.RectangleF (30*$s), (30*$s), (196*$s), (196*$s)
$path.AddArc($rect.X, $rect.Y, $r*2, $r*2, 180, 90)
$path.AddArc($rect.Right - $r*2, $rect.Y, $r*2, $r*2, 270, 90)
$path.AddArc($rect.Right - $r*2, $rect.Bottom - $r*2, $r*2, $r*2, 0, 90)
$path.AddArc($rect.X, $rect.Bottom - $r*2, $r*2, $r*2, 90, 90)
$path.CloseFigure()
$g.FillPath($brush, $path)
```

### Outlines

```powershell
$pen = New-Object System.Drawing.Pen $color, ([Math]::Max(1, [int](4 * $s)))
$g.DrawEllipse($pen, (40*$s), (40*$s), (176*$s), (176*$s))
$g.DrawRectangle($pen, (30*$s), (30*$s), (196*$s), (196*$s))
```

## Effects

### Glow (draw wider semi-transparent layer behind main strokes)

```powershell
$glowPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(40, 0, 255, 65)), ([Math]::Max(3, [int](30 * $s)))
$glowPen.StartCap = $glowPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
# Draw glow FIRST, then main strokes on top
$g.DrawLine($glowPen, ...)
$g.DrawLine($mainPen, ...)  # narrower, fully opaque
```

### CRT Scan Lines

```powershell
$scanPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(20, 0, 0, 0)), 1
$step = [Math]::Max(2, [int](4 * $s))
for ($y = 0; $y -lt $Size; $y += $step) {
    $g.DrawLine($scanPen, 0, $y, $Size, $y)
}
```

### Gradient background

```powershell
$gradBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush (
    (New-Object System.Drawing.Point 0, 0),
    (New-Object System.Drawing.Point 0, $Size),
    [System.Drawing.Color]::FromArgb(255, 20, 20, 40),
    [System.Drawing.Color]::FromArgb(255, 40, 20, 60)
)
$g.FillRectangle($gradBrush, 0, 0, $Size, $Size)
```

## Writing Multi-Size ICO

```powershell
$sizes = @(256, 48, 32, 16)
$pngList = @()
foreach ($sz in $sizes) {
    $bmp = New-Icon $sz
    $ms  = New-Object System.IO.MemoryStream
    $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $pngList += ,@{ Size = $sz; Data = $ms.ToArray() }
    $bmp.Dispose(); $ms.Dispose()
}

$ico = New-Object System.IO.MemoryStream
$w   = New-Object System.IO.BinaryWriter $ico
$w.Write([uint16]0)                  # Reserved
$w.Write([uint16]1)                  # Type = ICO
$w.Write([uint16]$pngList.Count)     # Image count

$dataOffset = 6 + (16 * $pngList.Count)
foreach ($entry in $pngList) {
    $dim = if ($entry.Size -ge 256) { [byte]0 } else { [byte]$entry.Size }
    $w.Write($dim); $w.Write($dim)
    $w.Write([byte]0); $w.Write([byte]0)
    $w.Write([uint16]1); $w.Write([uint16]32)
    $w.Write([uint32]$entry.Data.Length)
    $w.Write([uint32]$dataOffset)
    $dataOffset += $entry.Data.Length
}
foreach ($entry in $pngList) { $w.Write($entry.Data) }
$w.Flush()

[System.IO.File]::WriteAllBytes($iconPath, $ico.ToArray())
$w.Dispose(); $ico.Dispose()
```
