# Luck-boost analysis: permanent luck passes vs timed personal luck vs server-wide luck.
param([string]$DataDir)
$ErrorActionPreference = "Stop"
$items = Import-Csv (Join-Path $DataDir "items-classified.csv")
$games = Import-Csv (Join-Path $DataDir "games-classified.csv")

$notBoost = "(?i)lucky block|lucky egg|egg|pack|bundle|skin|boat|hoverboard|breaker|enchant|treadmill|pickaxe|saurus|dino|tinkerer|racer|rolls? x|aura rolls|crate|chest|case|spin|wheel|ticket|grading|mutation luck|appraiser|biome reroll|heavenly|sword|pet\b|plushie|title|tag"
$testRx = "(?i)\btest\b|\[test\]"
function MinutesOf($text) {
	if ($text -match "(?i)(\d+(\.\d+)?)\s*(hours|hour|hrs|hr|h)\b") { return [double]$matches[1] * 60 }
	if ($text -match "(?i)(\d+)\s*(minutes|minute|mins|min|m)\b") { return [double]$matches[1] }
	return $null
}
$luck = foreach ($i in $items) {
	if ($i.isLuck -ne "True" -or $i.isAdPlaceholder -eq "True" -or $i.isGift -eq "True") { continue }
	if ($i.name -match $testRx) { continue }
	if ($i.name -match $notBoost) { continue }
	$p = [double]$i.price
	if ($p -le 0) { continue }
	$text = $i.name + " " + $i.description
	$type = if ($i.kind -eq "pass") { if ($i.isServerWide -eq "True") { "Permanent server luck pass" } else { "Permanent luck pass" } }
	        elseif ($i.isServerWide -eq "True") { "Server luck product" }
	        else { "Personal luck product" }
	[pscustomobject]@{ universeId = $i.universeId; game = $i.game; researchGenre = $i.researchGenre; type = $type; name = $i.name; price = $p; minutes = (MinutesOf $text); multiplier = $i.multiplier; description = $i.description }
}
$luck | Export-Csv (Join-Path $DataDir "luck-items.csv") -NoTypeInformation -Encoding UTF8

function Med($a) { $s = @($a | Sort-Object); if ($s.Count -eq 0) { return "" }; $m = [Math]::Floor($s.Count / 2); if ($s.Count % 2) { $s[$m] } else { ($s[$m - 1] + $s[$m]) / 2 } }
function Q($a, $q) { $s = @($a | Sort-Object); if ($s.Count -eq 0) { return "" }; $s[[Math]::Min($s.Count - 1, [Math]::Floor($q * ($s.Count - 1)))] }

"=== Luck item types across ALL games (cheapest-per-game removes bundles of the same item) ==="
foreach ($t in @("Permanent luck pass", "Permanent server luck pass", "Personal luck product", "Server luck product")) {
	$x = @($luck | Where-Object { $_.type -eq $t })
	$gamesWith = @($x | Select-Object -ExpandProperty universeId -Unique).Count
	$cheapest = @($x | Group-Object universeId | ForEach-Object { ($_.Group | Measure-Object price -Minimum).Minimum })
	$dearest = @($x | Group-Object universeId | ForEach-Object { ($_.Group | Measure-Object price -Maximum).Maximum })
	"{0}: items={1} games={2} | all-items median R$ {3} (p25 {4}, p75 {5}) | per-game cheapest median R$ {6} | per-game priciest median R$ {7}" -f $t, $x.Count, $gamesWith, (Med ($x.price)), (Q ($x.price) 0.25), (Q ($x.price) 0.75), (Med $cheapest), (Med $dearest)
}

"=== Timed items with a stated duration: Robux per 15 minutes ==="
foreach ($t in @("Personal luck product", "Server luck product")) {
	$x = @($luck | Where-Object { $_.type -eq $t -and $_.minutes })
	$per15 = @($x | ForEach-Object { $_.price / $_.minutes * 15 })
	"{0}: {1} items with duration | durations: {2} | median R$ per 15 min = {3} (p25 {4}, p75 {5})" -f $t, $x.Count, (($x | Group-Object minutes | Sort-Object { [double]$_.Name } | ForEach-Object { "$($_.Name)m x$($_.Count)" }) -join ", "), [Math]::Round((Med $per15), 1), [Math]::Round((Q $per15 0.25), 1), [Math]::Round((Q $per15 0.75), 1)
}

"=== By research genre: share of games selling each luck type ==="
$byGenre = foreach ($grp in ($games | Group-Object researchGenre)) {
	$ids = @($grp.Group.universeId)
	$has = { param($t) @($ids | Where-Object { $id = $_; @($luck | Where-Object { $_.universeId -eq $id -and $_.type -eq $t }).Count -gt 0 }).Count }
	$pp = & $has "Permanent luck pass"; $sp = & $has "Permanent server luck pass"; $pl = & $has "Personal luck product"; $sl = & $has "Server luck product"
	$anyPerm = @($ids | Where-Object { $id = $_; @($luck | Where-Object { $_.universeId -eq $id -and $_.type -like "Permanent*" }).Count -gt 0 }).Count
	$anyTimed = @($ids | Where-Object { $id = $_; @($luck | Where-Object { $_.universeId -eq $id -and $_.type -like "*product" }).Count -gt 0 }).Count
	$both = @($ids | Where-Object { $id = $_; (@($luck | Where-Object { $_.universeId -eq $id -and $_.type -like "Permanent*" }).Count -gt 0) -and (@($luck | Where-Object { $_.universeId -eq $id -and $_.type -like "*product" }).Count -gt 0) }).Count
	[pscustomobject]@{ genre = $grp.Name; games = $grp.Count; permPass = $pp; permServerPass = $sp; personalProduct = $pl; serverProduct = $sl; anyPermanent = $anyPerm; anyRepeatable = $anyTimed; both = $both; onlyPermanent = $anyPerm - $both; onlyRepeatable = $anyTimed - $both }
}
$byGenre | Sort-Object games -Descending | Format-Table -AutoSize | Out-String -Width 250
$byGenre | Export-Csv (Join-Path $DataDir "luck-by-genre.csv") -NoTypeInformation -Encoding UTF8

"=== Permanent luck passes with stated effect (sample) ==="
$luck | Where-Object { $_.type -like "Permanent*" } | Sort-Object price | ForEach-Object { "{0} | R$ {1} | {2} | {3}" -f (($_.game -replace '[^\x20-\x7E]', '').Trim()), $_.price, ($_.name -replace '[^\x20-\x7E]', ''), ((($_.description -replace '[^\x20-\x7E]', '') -replace '\s+', ' ').Substring(0, [Math]::Min(80, (($_.description -replace '[^\x20-\x7E]', '') -replace '\s+', ' ').Length))) }
