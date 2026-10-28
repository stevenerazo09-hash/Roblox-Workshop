# Builds the Roblox store art from Studio captures (art/store/raw_*.jpg):
#   icon.png 512x512, thumb1.png and thumb2.png 1920x1080.
# The captures come from a playtest showcase of rare mages with auras (HUD,
# character and signs hidden, see Obsidian "Launch Plan"). Text is drawn with
# GDI+ (System.Drawing): gold fill, dark outline, soft drop shadow.
#   powershell -ExecutionPolicy Bypass -File art\make_store_art.ps1
param([string]$Dir = (Join-Path $PSScriptRoot "store"))
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$FONT = "Impact"
$GOLD_TOP = [System.Drawing.Color]::FromArgb(255, 255, 240, 130)
$GOLD_BOTTOM = [System.Drawing.Color]::FromArgb(255, 255, 165, 25)
$OUTLINE = [System.Drawing.Color]::FromArgb(255, 32, 12, 58)
$SHADOW = [System.Drawing.Color]::FromArgb(150, 0, 0, 0)

# Draws `src` cropped to the target aspect (centred, shifted by $shiftX of the
# spare width) and scaled to fill a new w x h bitmap.
function New-Canvas($src, [int]$w, [int]$h, [double]$shiftX = 0) {
	$bmp = New-Object System.Drawing.Bitmap $w, $h
	$g = [System.Drawing.Graphics]::FromImage($bmp)
	$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
	$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
	$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
	$targetAspect = $w / $h
	$cropW = [Math]::Min($src.Width, $src.Height * $targetAspect)
	$cropH = $cropW / $targetAspect
	$spare = $src.Width - $cropW
	$x0 = $spare / 2 + $shiftX * $spare / 2
	$y0 = ($src.Height - $cropH) / 2
	$dest = New-Object System.Drawing.Rectangle 0, 0, $w, $h
	$g.DrawImage($src, $dest, [single]$x0, [single]$y0, [single]$cropW, [single]$cropH, [System.Drawing.GraphicsUnit]::Pixel)
	return @{ Bitmap = $bmp; Graphics = $g }
}

# Outlined, gradient-filled text centred on (cx, cy), rotated by $angle degrees.
function Draw-Title($g, [string]$text, [double]$size, [double]$cx, [double]$cy, [double]$outline, [double]$angle = 0) {
	$path = New-Object System.Drawing.Drawing2D.GraphicsPath
	$family = New-Object System.Drawing.FontFamily $FONT
	$format = New-Object System.Drawing.StringFormat
	$format.Alignment = [System.Drawing.StringAlignment]::Center
	$format.LineAlignment = [System.Drawing.StringAlignment]::Center
	$path.AddString($text, $family, [int][System.Drawing.FontStyle]::Regular, [single]$size, (New-Object System.Drawing.PointF 0, 0), $format)
	$m = New-Object System.Drawing.Drawing2D.Matrix
	$m.Translate([single]$cx, [single]$cy)
	$m.Rotate([single]$angle)
	$path.Transform($m)
	$bounds = $path.GetBounds()

	# Drop shadow
	$shadowPath = $path.Clone()
	$sm = New-Object System.Drawing.Drawing2D.Matrix
	$sm.Translate([single]($outline * 0.45), [single]($outline * 0.6))
	$shadowPath.Transform($sm)
	$shadowPen = New-Object System.Drawing.Pen $SHADOW, ([single]($outline * 2))
	$shadowPen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
	$g.DrawPath($shadowPen, $shadowPath)
	$g.FillPath((New-Object System.Drawing.SolidBrush $SHADOW), $shadowPath)

	# Outline, then gradient fill
	$pen = New-Object System.Drawing.Pen $OUTLINE, ([single]($outline * 2))
	$pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
	$g.DrawPath($pen, $path)
	$brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush $bounds, $GOLD_TOP, $GOLD_BOTTOM, ([System.Drawing.Drawing2D.LinearGradientMode]::Vertical)
	$g.FillPath($brush, $path)
	$pen.Dispose(); $shadowPen.Dispose(); $brush.Dispose(); $path.Dispose(); $shadowPath.Dispose()
}

function Save-Png($canvas, [string]$name) {
	$out = Join-Path $Dir $name
	$canvas.Graphics.Dispose()
	$canvas.Bitmap.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
	$canvas.Bitmap.Dispose()
	$out
}

$wide = [System.Drawing.Image]::FromFile((Join-Path $Dir "raw_wide.jpg"))
$trio = [System.Drawing.Image]::FromFile((Join-Path $Dir "raw_trio.jpg"))
$close = [System.Drawing.Image]::FromFile((Join-Path $Dir "raw_icon.jpg"))
try {
	# Thumbnail 1: the lineup in front of the Grimoire Tower + game title
	$c = New-Canvas $wide 1920 1080
	Draw-Title $c.Graphics "BUILD A" 120 960 112 12 -3
	Draw-Title $c.Graphics "MAGE FARM" 255 960 270 20 -3
	Save-Png $c "thumb1.png"

	# Thumbnail 2: close-up of the Devil and two Archmages
	$c = New-Canvas $trio 1920 1080
	Draw-Title $c.Graphics "ROLL 42 MAGES!" 190 960 150 17 -2
	Draw-Title $c.Graphics "FROM COMMON TO 1-IN-A-MILLION" 82 960 990 10 0
	Save-Png $c "thumb2.png"

	# Icon: the Archmage with halo, square crop, short title
	$c = New-Canvas $close 512 512
	Draw-Title $c.Graphics "MAGE FARM" 96 256 448 9 -3
	Save-Png $c "icon.png"
} finally {
	$wide.Dispose(); $trio.Dispose(); $close.Dispose()
}
