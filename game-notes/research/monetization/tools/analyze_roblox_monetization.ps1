# Analyze collected public data: classify games into research genres, extract
# luck/boost items, and write summary CSVs for the notes.
param([string]$DataDir)
$ErrorActionPreference = "Stop"
$games = Import-Csv (Join-Path $DataDir "games.csv")
$items = Import-Csv (Join-Path $DataDir "items.csv")

# Chart genre (Roblox's genreL1) from the raw chart files
Add-Type -AssemblyName System.Web.Extensions
$ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer; $ser.MaxJsonLength = 200000000
$chartGenre = @{}
Get-ChildItem (Join-Path $DataDir "raw") -Filter "chart-*.json" | ForEach-Object {
	$o = $ser.DeserializeObject((Get-Content $_.FullName -Raw))
	foreach ($g in $o["games"]) { $chartGenre[[string]$g["universeId"]] = $g["genreL1"] }
}

function Classify($g) {
	$n = ($g.name + " ").ToLower()
	$genre = $chartGenre[$g.universeId]
	if (-not $genre) { $genre = $g.genre }
	if ($n -match "\brng\b|aura|gacha|dice|roll|lucky block|summon|\bspin\b|hatch|egg") { return "RNG and Gacha" }
	if ($n -match "tycoon|idle|grow a|steal a|steal an|build a|garden|farm|factory|restaurant|store|shop sim|mall") { return "Tycoons and Idle" }
	if ($n -match "simulator|per click|clicker|\+1 |rebirth|muscle|lifting|legends") { return "Simulators" }
	if ($n -match "obby|tower of|parkour|escape|jump|climb|stairs|glass bridge|platformer|difficulty chart") { return "Obby and Skill" }
	if ($genre -eq "Obby & Platformer") { return "Obby and Skill" }
	if ($n -match "\brp\b|roleplay|brookhaven|bloxburg|adopt me|royale high|berry avenue|livetopia|dress to impress|avenue|life|hangout|pls donate|vibe|cafe") { return "Roleplay and Social" }
	if ($genre -in @("Roleplay & Avatar Sim", "Social")) { return "Roleplay and Social" }
	if ($n -match "rivals|arsenal|bedwars|blade ball|battlegrounds|da hood|murder mystery|pvp|arena|duels|fighting|combat|war|sword|gun|shooter|jailbreak|prison|cops") { return "Competitive PvP" }
	if ($genre -in @("Shooter", "Sports & Racing")) { return "Competitive PvP" }
	if ($genre -eq "Simulation") { return "Simulators" }
	if ($n -match "defense|defence|anime|fruits|rpg|dungeon|quest") { return "RPG, Anime and Tower Defense" }
	if ($genre -in @("RPG", "Strategy")) { return "RPG, Anime and Tower Defense" }
	if ($genre -in @("Survival", "Adventure") -or $n -match "doors|nights|horror|survive|forest") { return "Survival, Horror and Adventure" }
	return "Other (" + $genre + ")"
}

# Overrides for well-known games where name rules mislead (checked by hand)
$override = @{}
$ovFile = Join-Path $DataDir "genre-overrides.csv"
if (Test-Path $ovFile) { Import-Csv $ovFile | ForEach-Object { $override[$_.universeId] = $_.researchGenre } }

foreach ($g in $games) {
	$cls = if ($override.ContainsKey($g.universeId)) { $override[$g.universeId] } else { Classify $g }
	$g | Add-Member -NotePropertyName researchGenre -NotePropertyValue $cls -Force
	$g | Add-Member -NotePropertyName chartGenre -NotePropertyValue $chartGenre[$g.universeId] -Force
}
$genreById = @{}; foreach ($g in $games) { $genreById[$g.universeId] = $g.researchGenre }

# Luck / boost / timed classification of items
$luckRx = "(?i)\bluck|lucky|clover"
$timedRx = "(?i)(\d+\s*(min|mins|minute|minutes|m|hour|hours|hr|hrs|h)\b)|for \d+|temporary|duration|lasts|timed"
$serverRx = "(?i)server"
$boostRx = "(?i)\b(2x|x2|3x|x3|double|triple|boost|potion|multiplier)\b"
$giftRx = "(?i)gift"
$out = foreach ($i in $items) {
	$price = 0.0; [void][double]::TryParse($i.price, [ref]$price)
	$text = $i.name + " " + $i.description
	[pscustomobject]@{
		universeId = $i.universeId; game = $i.game; researchGenre = $genreById[$i.universeId]; kind = $i.kind; name = $i.name; price = $price
		isLuck = [bool]($i.name -match $luckRx -or ($i.description -match $luckRx -and $i.name -match $boostRx))
		isTimed = [bool]($text -match $timedRx)
		isServerWide = [bool]($i.name -match $serverRx)
		isBoost = [bool]($text -match $boostRx)
		isGift = [bool]($i.name -match $giftRx)
		isAdPlaceholder = [bool]($price -ge 1000000)
		multiplier = $(if ($text -match "(?i)(\d+(\.\d+)?)\s*x\b|\bx\s*(\d+(\.\d+)?)") { if ($matches[1]) { $matches[1] } else { $matches[3] } } else { "" })
		description = $i.description
	}
}
$out | Export-Csv (Join-Path $DataDir "items-classified.csv") -NoTypeInformation -Encoding UTF8
$games | Export-Csv (Join-Path $DataDir "games-classified.csv") -NoTypeInformation -Encoding UTF8

function Med($a) { $s = @($a | Sort-Object); if ($s.Count -eq 0) { return "" }; $m = [Math]::Floor($s.Count / 2); if ($s.Count % 2) { $s[$m] } else { ($s[$m - 1] + $s[$m]) / 2 } }
function Pct($n, $d) { if ($d -eq 0) { "" } else { [Math]::Round(100 * $n / $d) } }

# Per-genre summary
$summary = foreach ($grp in ($games | Group-Object researchGenre | Sort-Object Count -Descending)) {
	$ids = @($grp.Group | ForEach-Object { $_.universeId })
	$gi = @($out | Where-Object { $ids -contains $_.universeId -and -not $_.isAdPlaceholder })
	$passes = @($gi | Where-Object { $_.kind -eq "pass" -and $_.price -gt 0 })
	$prods = @($gi | Where-Object { $_.kind -eq "product" -and $_.price -gt 0 })
	$withLuckPass = @($ids | Where-Object { $id = $_; @($passes | Where-Object { $_.universeId -eq $id -and $_.isLuck }).Count -gt 0 }).Count
	$withLuckProd = @($ids | Where-Object { $id = $_; @($prods | Where-Object { $_.universeId -eq $id -and $_.isLuck }).Count -gt 0 }).Count
	$withBoth = @($ids | Where-Object { $id = $_; @($passes | Where-Object { $_.universeId -eq $id -and $_.isLuck }).Count -gt 0 -and @($prods | Where-Object { $_.universeId -eq $id -and $_.isLuck }).Count -gt 0 }).Count
	$withGift = @($ids | Where-Object { $id = $_; @($gi | Where-Object { $_.universeId -eq $id -and $_.isGift }).Count -gt 0 }).Count
	$withAd = @($grp.Group | Where-Object { [int]$_.adPlaceholderProducts -gt 0 }).Count
	$perGamePassMed = @($grp.Group | Where-Object { $_.passMedian } | ForEach-Object { [double]$_.passMedian })
	$perGameProdMed = @($grp.Group | Where-Object { $_.productMedian } | ForEach-Object { [double]$_.productMedian })
	[pscustomobject]@{
		researchGenre = $grp.Name; games = $grp.Count
		medianPlaying = (Med @($grp.Group | ForEach-Object { [double]$_.playing }))
		medianPassesPerGame = (Med @($grp.Group | ForEach-Object { [double]$_.passesForSale }))
		medianProductsPerGame = (Med @($grp.Group | ForEach-Object { [double]$_.productsForSale }))
		typicalPassPrice = (Med $perGamePassMed); typicalProductPrice = (Med $perGameProdMed)
		allPassP25 = (Med @($passes | Sort-Object price | Select-Object -First ([Math]::Max(1, [Math]::Floor($passes.Count / 2))) | ForEach-Object { $_.price }))
		pctGamesWithLuckPass = (Pct $withLuckPass $grp.Count); pctGamesWithLuckProduct = (Pct $withLuckProd $grp.Count); pctGamesWithBoth = (Pct $withBoth $grp.Count)
		pctGamesWithGiftProducts = (Pct $withGift $grp.Count); pctGamesWithAdRewardProducts = (Pct $withAd $grp.Count)
	}
}
$summary | Export-Csv (Join-Path $DataDir "genre-summary.csv") -NoTypeInformation -Encoding UTF8
$summary | Format-Table -AutoSize | Out-String -Width 300
