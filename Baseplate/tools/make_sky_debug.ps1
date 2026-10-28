# Writes 6 labelled test faces (assets/images/skydebug_*.png) to check how
# Roblox orients each Sky face: the face name in the middle, and TOP / BOT / L / R
# written along the edges, so a screenshot shows each face's rotation.
Add-Type -AssemblyName System.Drawing
$out = Join-Path (Split-Path $PSScriptRoot -Parent) "assets\images"
$faces = @{
	Bk = [System.Drawing.Color]::FromArgb(200, 60, 60)
	Ft = [System.Drawing.Color]::FromArgb(60, 160, 60)
	Lf = [System.Drawing.Color]::FromArgb(60, 80, 200)
	Rt = [System.Drawing.Color]::FromArgb(200, 170, 40)
	Up = [System.Drawing.Color]::FromArgb(150, 60, 190)
	Dn = [System.Drawing.Color]::FromArgb(40, 170, 170)
}
foreach ($name in $faces.Keys) {
	$bmp = New-Object System.Drawing.Bitmap 256, 256
	$g = [System.Drawing.Graphics]::FromImage($bmp)
	$g.Clear($faces[$name])
	$font = New-Object System.Drawing.Font "Arial", 64, ([System.Drawing.FontStyle]::Bold)
	$small = New-Object System.Drawing.Font "Arial", 22, ([System.Drawing.FontStyle]::Bold)
	$white = [System.Drawing.Brushes]::White
	$fmt = New-Object System.Drawing.StringFormat
	$fmt.Alignment = [System.Drawing.StringAlignment]::Center
	$fmt.LineAlignment = [System.Drawing.StringAlignment]::Center
	$g.DrawString($name.ToUpper(), $font, $white, (New-Object System.Drawing.RectangleF 0, 0, 256, 256), $fmt)
	$g.DrawString("TOP", $small, $white, (New-Object System.Drawing.RectangleF 0, 0, 256, 40), $fmt)
	$g.DrawString("BOT", $small, $white, (New-Object System.Drawing.RectangleF 0, 216, 256, 40), $fmt)
	$g.DrawString("L", $small, $white, (New-Object System.Drawing.RectangleF 0, 0, 40, 256), $fmt)
	$g.DrawString("R", $small, $white, (New-Object System.Drawing.RectangleF 216, 0, 40, 256), $fmt)
	$g.DrawRectangle((New-Object System.Drawing.Pen ([System.Drawing.Color]::Black), 6), 0, 0, 255, 255)
	$g.Dispose()
	$bmp.Save((Join-Path $out "skydebug_$name.png"), [System.Drawing.Imaging.ImageFormat]::Png)
	$bmp.Dispose()
}
Get-ChildItem $out -Filter "skydebug_*.png" | Select-Object Name, Length
