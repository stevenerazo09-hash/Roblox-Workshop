# Prints "<Studio path> len=<bytes> adler=<adler32>" for every script in src/,
# to compare with the same numbers computed inside Studio (see README: "Keeping
# Studio and src/ in sync"). Studio paths come from default.project.json (Rojo
# layout: src/shared -> ReplicatedStorage.Shared, ...); without a project file the
# folder names are the Studio names (old layout: src/ReplicatedStorage/...).
# Files must be LF: Studio stores Source byte for byte.
# -Snippet prints Luau for Studio's command bar that prints the same lines there.
param([string]$Root = (Split-Path $PSScriptRoot -Parent), [switch]$Snippet)

$script:mounts = @()
function Add-Mounts($node, [string[]]$path) {
	foreach ($p in $node.PSObject.Properties) {
		if ($p.Name.StartsWith('$') -or -not ($p.Value -is [System.Management.Automation.PSCustomObject])) { continue }
		$here = @($path) + $p.Name
		$dir = $p.Value.'$path'
		if ($dir) { $script:mounts += [pscustomobject]@{ Dir = ($dir -replace '\\', '/' -replace '^\./', '').TrimEnd('/'); Path = $here } }
		Add-Mounts $p.Value $here
	}
}
$project = Join-Path $Root "default.project.json"
if (Test-Path -LiteralPath $project) {
	Add-Mounts (Get-Content -LiteralPath $project -Raw | ConvertFrom-Json).tree @()
}

$src = Join-Path $Root "src"
$rows = Get-ChildItem -LiteralPath $src -Recurse -File | Where-Object { $_.Extension -in '.lua', '.luau' } | Sort-Object FullName | ForEach-Object {
	$rel = "src/" + ($_.FullName.Substring($src.Length + 1) -replace '\\', '/')
	$mount = $script:mounts | Where-Object { $rel.StartsWith($_.Dir + '/') } | Sort-Object { $_.Dir.Length } -Descending | Select-Object -First 1
	if ($mount) { $parts = @($mount.Path) + $rel.Substring($mount.Dir.Length + 1).Split('/') }
	else { $parts = $rel.Substring(4).Split('/') }
	$dirs = @()
	if ($parts.Count -gt 1) { $dirs = $parts[0..($parts.Count - 2)] }
	$name = $parts[-1] -replace '\.luau?$', '' -replace '\.(server|client)$', ''
	# init.* is the folder's own script
	if ($name -eq 'init') { $path = $dirs -join '.' } else { $path = (@($dirs) + $name) -join '.' }
	$bytes = [System.IO.File]::ReadAllBytes($_.FullName)
	$a = 1; $b = 0
	foreach ($x in $bytes) { $a = ($a + $x) % 65521; $b = ($b + $a) % 65521 }
	[pscustomobject]@{ Path = $path; Len = $bytes.Length; Adler = $b * 65536 + $a; CRLF = ($bytes -contains 13) }
}

if ($Snippet) {
	"local paths={" + (($rows | ForEach-Object { '"' + $_.Path + '"' }) -join ',') + "}"
	'for _,p in paths do local i=game for s in p:gmatch("[^%.]+") do i=i:FindFirstChild(s) or game:GetService(s) end local src=i.Source local a,b=1,0 for k=1,#src do a=(a+src:byte(k))%65521 b=(b+a)%65521 end print(p,"len="..#src,"adler="..(b*65536+a)) end'
} else {
	foreach ($r in $rows) {
		$line = "{0} len={1} adler={2}" -f $r.Path, $r.Len, $r.Adler
		if ($r.CRLF) { $line += "  (CRLF line endings: convert to LF, or it can't match Studio)" }
		$line
	}
}
