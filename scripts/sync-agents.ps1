# Copies agents/*.md to %USERPROFILE%\.claude\agents\.
# Skips agents marked disabled in agents/VERSIONS.md. Never deletes anything in the destination.
$root = Split-Path $PSScriptRoot -Parent
$dest = Join-Path $env:USERPROFILE '.claude\agents'
New-Item -ItemType Directory -Force $dest | Out-Null
$versions = Get-Content (Join-Path $root 'agents\VERSIONS.md')
foreach ($f in Get-ChildItem (Join-Path $root 'agents') -Filter *.md) {
    if ($f.Name -eq 'VERSIONS.md') { continue }
    $name = $f.BaseName
    if ($versions | Where-Object { $_ -match "^\|\s*$name\s*\|.*\|\s*disabled\s*\|" }) { "skipped (disabled): $name"; continue }
    Copy-Item $f.FullName (Join-Path $dest $f.Name) -Force
    "synced: $name"
}
