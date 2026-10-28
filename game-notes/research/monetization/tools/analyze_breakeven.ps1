# For games selling BOTH a permanent boost pass and a timed boost product of the
# same stat (luck / xp / money), compute: hours of timed boost that cost the same
# as the permanent pass ("break-even hours").
param([string]$DataDir)
$ErrorActionPreference = "Stop"
$items = Import-Csv (Join-Path $DataDir "items-classified.csv") | Where-Object { $_.isAdPlaceholder -eq "False" -and $_.isGift -eq "False" -and [double]$_.price -gt 0 -and $_.name -notmatch "(?i)\btest\b" }
$games = Import-Csv (Join-Path $DataDir "games-classified.csv")
$stat = [ordered]@{ luck = "(?i)\bluck"; xp = "(?i)\b(xp|exp|experience|mastery)\b"; money = "(?i)\b(cash|money|coins?|income|yul|bucks)\b" }
$isBoost = "(?i)\b(2x|x2|3x|x3|double|boost|booster|potion|multiplier|\d+(\.\d+)?x|x\d+)\b|\+\d+%|\d+%"
$exclude = "(?i)lucky block|egg|pack\b|bundle|chest|crate|case|spin|server|treadmill|pickaxe|skin|trail|reroll|appraiser"
function MinutesOf($t) {
	# Only explicit time words; bare "m"/"h" are too often money amounts ("1.8M Money").
	if ($t -match "(?i)(\d+(\.\d+)?)\s*(hours|hour|hrs|hr)\b") { return [double]$matches[1] * 60 }
	if ($t -match "(?i)(\d+)\s*(minutes|minute|mins|min)\b") { return [double]$matches[1] }
	if ($t -match "(?i)(\d+)\s*h\)") { return [double]$matches[1] * 60 }
	return $null
}
$rows = foreach ($g in $games) {
	$gi = @($items | Where-Object { $_.universeId -eq $g.universeId })
	foreach ($k in $stat.Keys) {
		$passes = @($gi | Where-Object { $_.kind -eq "pass" -and $_.name -match $stat[$k] -and $_.name -notmatch $exclude -and (($_.name + " " + $_.description) -match $isBoost -or $_.name -match "(?i)^\s*(luck|lucky)\s*!?$") })
		$timed = @($gi | Where-Object { $_.kind -eq "product" -and $_.name -match $stat[$k] -and $_.name -notmatch $exclude } | ForEach-Object { $m = MinutesOf ($_.name + " " + $_.description); if ($m) { $_ | Add-Member -NotePropertyName minutes -NotePropertyValue $m -PassThru -Force } })
		if ($passes.Count -and $timed.Count) {
			$cheapPass = $passes | Sort-Object { [double]$_.price } | Select-Object -First 1
			$bestHourly = $timed | Sort-Object { [double]$_.price / $_.minutes } | Select-Object -First 1
			$perHour = [double]$bestHourly.price / $bestHourly.minutes * 60
			[pscustomobject]@{
				game = ($g.name -replace '[^\x20-\x7E]', '').Trim(); genre = $g.researchGenre; stat = $k
				pass = ($cheapPass.name -replace '[^\x20-\x7E]', '').Trim(); passPrice = [double]$cheapPass.price
				timed = ($bestHourly.name -replace '[^\x20-\x7E]', '').Trim(); timedPrice = [double]$bestHourly.price; timedMinutes = $bestHourly.minutes
				robuxPerHour = [Math]::Round($perHour, 1); breakEvenHours = [Math]::Round([double]$cheapPass.price / $perHour, 1)
				passToCheapestTimedRatio = [Math]::Round([double]$cheapPass.price / (@($timed | ForEach-Object { [double]$_.price } | Sort-Object)[0]), 1)
			}
		}
	}
}
$rows | Export-Csv (Join-Path $DataDir "breakeven.csv") -NoTypeInformation -Encoding UTF8
$rows | Sort-Object breakEvenHours | Format-Table game, stat, pass, passPrice, timed, timedPrice, timedMinutes, robuxPerHour, breakEvenHours, passToCheapestTimedRatio -AutoSize | Out-String -Width 300
$h = @($rows | ForEach-Object { $_.breakEvenHours } | Sort-Object)
if ($h.Count) { "pairs: {0} | median break-even hours: {1} | p25 {2} | p75 {3}" -f $h.Count, $h[[Math]::Floor(($h.Count - 1) / 2)], $h[[Math]::Floor(0.25 * ($h.Count - 1))], $h[[Math]::Floor(0.75 * ($h.Count - 1))] }
$r = @($rows | ForEach-Object { $_.passToCheapestTimedRatio } | Sort-Object)
if ($r.Count) { "median pass / cheapest timed price ratio: {0} (p25 {1}, p75 {2})" -f $r[[Math]::Floor(($r.Count - 1) / 2)], $r[[Math]::Floor(0.25 * ($r.Count - 1))], $r[[Math]::Floor(0.75 * ($r.Count - 1))] }
