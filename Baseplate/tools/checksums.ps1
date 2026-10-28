# Prints "<Studio path> len=<bytes> adler=<adler32>" for every script in src/,
# to compare with the same numbers computed inside Studio (see README: "Check
# Studio matches src/"). Files are LF; Studio stores Source byte for byte.
param([string]$Root = (Split-Path $PSScriptRoot -Parent))
$src = Join-Path $Root "src"
Get-ChildItem $src -Recurse -File -Filter *.lua | Sort-Object FullName | ForEach-Object {
	$rel = $_.FullName.Substring($src.Length + 1) -replace "\\", "/"
	$parts = $rel.Split("/")
	$file = $parts[-1]
	$dirs = $parts[0..($parts.Length - 2)]
	if ($file -eq "init.lua" -or $file -eq "init.client.lua" -or $file -eq "init.server.lua") { $name = @() }
	else { $name = @($file -replace "\.(server|client)\.lua$", "" -replace "\.lua$", "") }
	$path = (@($dirs) + $name) -join "."
	$bytes = [System.IO.File]::ReadAllBytes($_.FullName)
	$a = 1; $b = 0
	foreach ($x in $bytes) { $a = ($a + $x) % 65521; $b = ($b + $a) % 65521 }
	"{0} len={1} adler={2}" -f $path, $bytes.Length, ($b * 65536 + $a)
}
