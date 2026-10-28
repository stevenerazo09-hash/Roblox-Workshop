# "Moment" products: items whose names show WHERE the game prompts a purchase
# (shortfall / waiting / failure / streak loss). Share of games per genre + median price.
param([string]$DataDir)
$ErrorActionPreference = "Stop"
$items = Import-Csv (Join-Path $DataDir "items-classified.csv") | Where-Object { $_.kind -eq "product" -and $_.isAdPlaceholder -eq "False" -and $_.isGift -eq "False" -and [double]$_.price -gt 0 -and $_.name -notmatch "(?i)\btest\b" }
$games = Import-Csv (Join-Path $DataDir "games-classified.csv")
$moments = [ordered]@{
	"Shortfall: instant buy / buy-out an upgrade" = "(?i)instant (buy|unlock|upgrade|purchase)|buy (this|item|common|uncommon|rare|1 egg)|skip (speed )?upgrade|skip rebirth|skip (base|tier)\b|unlock (this|first|second|third|base|floor|nest)|purchase 1"
	"Waiting: skip timer / growth / hatch / restock" = "(?i)skip (the )?timer|skip (egg )?growth|skip incubation|instant hatch|skip (time|cooldown)|restock|refresh (daily|stock|shop|quests?|tasks)|reroll stock|next day|day skip"
	"Failure: revive / respawn / self-rescue / extra time" = "(?i)revive|respawn|self-rescue|second chance|extra life|\+\d+ seconds|restore the killstreak|escape\b"
	"Streak repair: missed day / buyback" = "(?i)missed (advent )?day|streak|buyback|claim missed|return streak"
	"Currency top-up (amount or pack)" = "(?i)^\s*\+?[\d,\.]+\s*[kmb]?\s*(cash|coins?|gems?|diamonds?|bucks|tokens?|credits?|money|gold|keys?|candy|candies|knobs|screws|yen)\b|cash pack|coin pack|gem pack|money pack|currency|pile of|bag of|stack of|pouch of|chest of|\$[\d,\.]+\s*[kmb]?\b"
}
$rows = foreach ($grp in ($games | Group-Object researchGenre | Where-Object { $_.Name -notlike "Other*" })) {
	$ids = @($grp.Group.universeId)
	$gi = @($items | Where-Object { $ids -contains $_.universeId })
	$o = [ordered]@{ genre = $grp.Name; games = $grp.Count }
	foreach ($k in $moments.Keys) {
		$hit = @($gi | Where-Object { $_.name -match $moments[$k] })
		$gamesHit = @($hit | Select-Object -ExpandProperty universeId -Unique).Count
		$med = if ($hit.Count) { $s = @($hit | ForEach-Object { [double]$_.price } | Sort-Object); $s[[Math]::Floor(($s.Count - 1) / 2)] } else { "-" }
		$o[$k] = "{0}% (R$ {1})" -f [Math]::Round(100 * $gamesHit / $grp.Count), $med
	}
	[pscustomobject]$o
}
$rows | Export-Csv (Join-Path $DataDir "moments-by-genre.csv") -NoTypeInformation -Encoding UTF8
foreach ($r in $rows) { "--- " + $r.genre + " (" + $r.games + " games)"; foreach ($k in $moments.Keys) { "   {0,-50} {1}" -f $k, $r.$k } }
# All-genre totals
$all = @($items | Where-Object { $_.researchGenre -notlike "Other*" })
$n = @($games | Where-Object { $_.researchGenre -notlike "Other*" }).Count
"--- ALL research genres ($n games)"
foreach ($k in $moments.Keys) { $hit = @($all | Where-Object { $_.name -match $moments[$k] }); "   {0,-50} {1}% of games, {2} items" -f $k, [Math]::Round(100 * @($hit | Select-Object -ExpandProperty universeId -Unique).Count / $n), $hit.Count }
