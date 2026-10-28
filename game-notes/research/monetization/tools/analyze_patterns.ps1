# Keyword patterns per genre + example item lists for the top games in each genre.
param([string]$DataDir)
$ErrorActionPreference = "Stop"
$items = Import-Csv (Join-Path $DataDir "items-classified.csv") | Where-Object { $_.isAdPlaceholder -eq "False" -and [double]$_.price -gt 0 -and $_.name -notmatch "(?i)\btest\b" }
$games = Import-Csv (Join-Path $DataDir "games-classified.csv")
$patterns = [ordered]@{
	"Starter/beginner pack" = "(?i)starter|beginner|newbie|welcome pack"
	"VIP" = "(?i)\bvip\b"
	"2x money/currency" = "(?i)(2x|x2|double|3x|x3).*(cash|money|coins?|gems?|yul|bucks|income|gold|points)|(cash|money|coins?|income).*(2x|x2|double)"
	"Auto (collect/roll/farm)" = "(?i)\bauto\b"
	"Skip stage / skip" = "(?i)\bskip"
	"Revive / extra life" = "(?i)revive|extra life|second chance|respawn"
	"Admin / commands" = "(?i)\badmin\b|commands|\bkick\b"
	"Radio / boombox" = "(?i)radio|boombox|music"
	"Speed / jump / coil" = "(?i)speed|coil|jump"
	"Extra slots / storage" = "(?i)slot|storage|inventory|backpack|capacity"
	"Luck" = "(?i)\bluck|lucky"
	"Server-wide boost" = "(?i)server (luck|boost)|for everyone|whole server"
	"Currency pack (amount)" = "(?i)^\s*[\d,\.]+\s*[kmb]?\s*(cash|coins?|gems?|diamonds?|bucks|tokens?|credits?|money|gold|keys?)\b|(cash|coins?|gems?|diamonds?|bucks|tokens?|credits?|keys?)\s*[\d,\.]+\s*[kmb]?\s*$|pile of|bag of|chest of"
	"Bundle / pack" = "(?i)bundle|pack\b|package"
	"Seasonal / limited" = "(?i)limited|halloween|christmas|xmas|winter|summer|easter|valentine|event|season|anniversary"
	"Battle/season pass" = "(?i)battle ?pass|season pass|premium pass|seasonal pass"
	"Gift copy" = "(?i)gift"
	"Donation" = "(?i)donat|tip jar|support (the )?dev"
	"Private server / reserved" = "(?i)private server|vip server"
	"Pet / egg / unit" = "(?i)\bpets?\b|\beggs?\b|\bunits?\b|summon"
}
$rows = foreach ($grp in ($games | Group-Object researchGenre | Where-Object { $_.Name -notlike "Other*" })) {
	$ids = @($grp.Group.universeId)
	$gi = @($items | Where-Object { $ids -contains $_.universeId })
	$o = [ordered]@{ genre = $grp.Name; games = $grp.Count }
	foreach ($k in $patterns.Keys) {
		$hit = @($gi | Where-Object { $_.name -match $patterns[$k] })
		$gamesHit = @($hit | Select-Object -ExpandProperty universeId -Unique).Count
		$med = if ($hit.Count) { $s = @($hit | ForEach-Object { [double]$_.price } | Sort-Object); $s[[Math]::Floor(($s.Count - 1) / 2)] } else { "" }
		$o[$k] = "{0}% (R$ {1})" -f [Math]::Round(100 * $gamesHit / $grp.Count), $med
	}
	[pscustomobject]$o
}
$rows | Export-Csv (Join-Path $DataDir "patterns-by-genre.csv") -NoTypeInformation -Encoding UTF8
foreach ($r in $rows) { "--- " + $r.genre + " (" + $r.games + " games)"; foreach ($k in $patterns.Keys) { "   {0,-28} {1}" -f $k, $r.$k } }

# Example listings: top 4 games per genre by current players
$out = New-Object System.Collections.Generic.List[string]
foreach ($grp in ($games | Group-Object researchGenre | Where-Object { $_.Name -notlike "Other*" })) {
	$out.Add("## " + $grp.Name)
	foreach ($g in ($grp.Group | Sort-Object { [double]$_.playing } -Descending | Select-Object -First 5)) {
		$gi = @($items | Where-Object { $_.universeId -eq $g.universeId -and $_.isGift -eq "False" })
		$passes = @($gi | Where-Object { $_.kind -eq "pass" } | Sort-Object { [double]$_.price } | ForEach-Object { ($_.name -replace '[^\x20-\x7E]', '').Trim() + " " + $_.price })
		$prods = @($gi | Where-Object { $_.kind -eq "product" })
		$prodPrices = @($prods | ForEach-Object { [double]$_.price } | Sort-Object)
		$out.Add(("### {0} (universe {1}, playing {2}, genre {3})" -f ($g.name -replace '[^\x20-\x7E]', '').Trim(), $g.universeId, $g.playing, $g.chartGenre))
		$out.Add("PASSES: " + ($passes -join " | "))
		$out.Add(("PRODUCTS: {0} for sale, min {1}, median {2}, max {3}" -f $prods.Count, $(if ($prodPrices.Count) { $prodPrices[0] }), $(if ($prodPrices.Count) { $prodPrices[[Math]::Floor(($prodPrices.Count - 1) / 2)] }), $(if ($prodPrices.Count) { $prodPrices[-1] })))
		$sample = @($prods | Sort-Object { [double]$_.price } | Group-Object { ($_.name -replace '\d', '#') } | Select-Object -First 18 | ForEach-Object { $_.Group[0] } | ForEach-Object { ($_.name -replace '[^\x20-\x7E]', '').Trim() + " " + $_.price })
		$out.Add("PRODUCT SAMPLE: " + ($sample -join " | "))
	}
}
Set-Content -Path (Join-Path $DataDir "examples-by-genre.txt") -Value $out -Encoding UTF8
"examples written"
