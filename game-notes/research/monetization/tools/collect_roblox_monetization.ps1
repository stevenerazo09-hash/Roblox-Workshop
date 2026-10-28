# Read-only collection of public Roblox game monetization data (passes, developer
# products, player counts) for research notes. GET requests only, polite delays.
param(
	[string]$OutDir,
	[string[]]$ExtraNames = @(),
	[string[]]$UniverseIds = @(),
	[switch]$SkipCharts,
	[string]$Suffix = ""
)
$ErrorActionPreference = "Continue"
Add-Type -AssemblyName System.Web.Extensions
$ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$ser.MaxJsonLength = 200000000
$h = @{ "User-Agent" = "Mozilla/5.0 (Roblox monetization research; read-only)" }
$stamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$raw = Join-Path $OutDir "raw"
New-Item -ItemType Directory -Force -Path $raw | Out-Null

function Get-Json([string]$url) {
	for ($try = 1; $try -le 4; $try++) {
		try {
			$c = (Invoke-WebRequest -Uri $url -Headers $h -TimeoutSec 40 -UseBasicParsing).Content
			Start-Sleep -Milliseconds 250
			return @{ text = $c; obj = $ser.DeserializeObject($c) }
		} catch {
			$msg = $_.Exception.Message
			if ($msg -match "429") { Start-Sleep -Seconds (5 * $try) } else { Start-Sleep -Milliseconds 800 }
			if ($try -eq 4) { Write-Output "FAIL $url :: $msg"; return $null }
		}
	}
}

# 1. Charts
$games = [ordered]@{}
$chartRank = @{}
foreach ($u in $UniverseIds) {
	if (-not $games.Contains($u)) { $games[$u] = @{ universeId = $u; name = ""; genre = ""; maturity = ""; chartPlayers = $null; up = $null; down = $null; source = "manual" } }
}
$sorts = if ($SkipCharts) { @() } else { @("top-playing-now", "top-trending", "up-and-coming", "top-revisited", "fun-with-friends") }
foreach ($sort in $sorts) {
	$r = Get-Json "https://apis.roblox.com/explore-api/v1/get-sort-content?sessionId=research1&sortId=$sort&device=all&country=all"
	if (-not $r) { continue }
	Set-Content -Path (Join-Path $raw "chart-$sort.json") -Value $r.text -Encoding UTF8
	$i = 0
	foreach ($g in $r.obj["games"]) {
		$i++
		$id = [string]$g["universeId"]
		if (-not $games.Contains($id)) {
			$games[$id] = @{ universeId = $id; name = $g["name"]; genre = $g["genreL1"]; maturity = $g["contentMaturity"]; chartPlayers = $g["playerCount"]; up = $g["totalUpVotes"]; down = $g["totalDownVotes"]; source = $sort }
		}
		$chartRank["$sort|$id"] = $i
	}
}

# 2. Extra named games (genre examples)
foreach ($n in $ExtraNames) {
	$q = [uri]::EscapeDataString($n)
	$r = Get-Json "https://apis.roblox.com/search-api/omni-search?searchQuery=$q&pageType=all&sessionId=research1"
	if (-not $r) { continue }
	$best = $null
	foreach ($sr in $r.obj["searchResults"]) {
		foreach ($c in $sr["contents"]) {
			if ($c["universeId"] -and (-not $best -or [int64]$c["playerCount"] -gt [int64]$best["playerCount"])) { $best = $c }
		}
	}
	if ($best) {
		$id = [string]$best["universeId"]
		if (-not $games.Contains($id)) {
			$games[$id] = @{ universeId = $id; name = $best["name"]; genre = ""; maturity = ""; chartPlayers = $best["playerCount"]; up = $null; down = $null; source = "search:$n" }
		}
	}
}

# 3. Game details in batches of 40
$ids = @($games.Keys)
for ($i = 0; $i -lt $ids.Count; $i += 40) {
	$batch = $ids[$i..([Math]::Min($i + 39, $ids.Count - 1))] -join ","
	$r = Get-Json "https://games.roblox.com/v1/games?universeIds=$batch"
	if (-not $r) { continue }
	foreach ($d in $r.obj["data"]) {
		$g = $games[[string]$d["id"]]
		$g.playing = $d["playing"]; $g.visits = $d["visits"]; $g.created = $d["created"]; $g.updated = $d["updated"]
		$g.creator = $d["creator"]["name"]; $g.genreApi = $d["genre"]; $g.paidAccess = $d["price"]; $g.fullName = $d["name"]
		if (-not $g.genre) { $g.genre = $d["genre_l1"] }
	}
}

# 4. Passes and developer products per game
$rows = New-Object System.Collections.Generic.List[object]
$items = New-Object System.Collections.Generic.List[object]
foreach ($id in $ids) {
	$g = $games[$id]
	# passes
	$passes = New-Object System.Collections.Generic.List[object]
	$token = ""
	for ($page = 0; $page -lt 10; $page++) {
		$url = "https://apis.roblox.com/game-passes/v1/universes/$id/game-passes?passView=Full&pageSize=100"
		if ($token) { $url += "&pageToken=" + [uri]::EscapeDataString($token) }
		$r = Get-Json $url
		if (-not $r) { break }
		foreach ($p in $r.obj["gamePasses"]) { $passes.Add($p) }
		$token = $r.obj["nextPageToken"]
		if (-not $token) { break }
	}
	Set-Content -Path (Join-Path $raw "$id-passes.json") -Value ($ser.Serialize($passes)) -Encoding UTF8
	# developer products
	$prods = New-Object System.Collections.Generic.List[object]
	$cursor = ""
	for ($page = 0; $page -lt 20; $page++) {
		$url = "https://apis.roblox.com/developer-products/v2/universes/$id/developerproducts?limit=50"
		if ($cursor) { $url += "&cursor=" + [uri]::EscapeDataString($cursor) }
		$r = Get-Json $url
		if (-not $r) { break }
		foreach ($p in $r.obj["developerProducts"]) { $prods.Add($p) }
		$cursor = $r.obj["nextPageCursor"]
		if (-not $cursor) { break }
	}
	Set-Content -Path (Join-Path $raw "$id-products.json") -Value ($ser.Serialize($prods)) -Encoding UTF8

	$passPrices = @($passes | Where-Object { $_["isForSale"] -and $_["price"] } | ForEach-Object { [double]$_["price"] } | Sort-Object)
	$prodPrices = @($prods | Where-Object { $_["IsForSale"] -and $_["PriceInRobux"] -and [double]$_["PriceInRobux"] -lt 1000000 } | ForEach-Object { [double]$_["PriceInRobux"] } | Sort-Object)
	function Median($a) { if ($a.Count -eq 0) { return $null }; $m = [Math]::Floor($a.Count / 2); if ($a.Count % 2) { return $a[$m] } else { return ($a[$m - 1] + $a[$m]) / 2 } }
	$adPlaceholders = @($prods | Where-Object { [double]$_["PriceInRobux"] -ge 1000000 }).Count
	$gifts = @($prods | Where-Object { $_["Name"] -match "(?i)gift" }).Count
	$rows.Add([pscustomobject]@{
		universeId = $id; name = $g.fullName; genre = $g.genre; maturity = $g.maturity; playing = $g.playing; visits = $g.visits
		upRatio = $(if ($g.up -and ($g.up + $g.down)) { [Math]::Round($g.up / ($g.up + $g.down), 3) } else { $null })
		created = $g.created; updated = $g.updated; creator = $g.creator; paidAccess = $g.paidAccess; source = $g.source
		passesForSale = $passPrices.Count; passMin = $(if ($passPrices.Count) { $passPrices[0] }); passMedian = (Median $passPrices); passMax = $(if ($passPrices.Count) { $passPrices[-1] })
		productsForSale = $prodPrices.Count; productMin = $(if ($prodPrices.Count) { $prodPrices[0] }); productMedian = (Median $prodPrices); productMax = $(if ($prodPrices.Count) { $prodPrices[-1] })
		adPlaceholderProducts = $adPlaceholders; giftProducts = $gifts; collectedUtc = $stamp
	})
	foreach ($p in $passes) {
		if ($p["isForSale"]) { $items.Add([pscustomobject]@{ universeId = $id; game = $g.fullName; kind = "pass"; name = $p["name"]; price = $p["price"]; description = ($p["displayDescription"] -replace "\s+", " ") }) }
	}
	foreach ($p in $prods) {
		if ($p["IsForSale"]) { $items.Add([pscustomobject]@{ universeId = $id; game = $g.fullName; kind = "product"; name = $p["Name"]; price = $p["PriceInRobux"]; description = ($p["Description"] -replace "\s+", " ") }) }
	}
	Write-Output ("{0} | {1} | passes {2} | products {3}" -f $id, $g.fullName, $passPrices.Count, $prodPrices.Count)
}
$rows | Export-Csv -Path (Join-Path $OutDir "games$Suffix.csv") -NoTypeInformation -Encoding UTF8
$items | Export-Csv -Path (Join-Path $OutDir "items$Suffix.csv") -NoTypeInformation -Encoding UTF8
Set-Content -Path (Join-Path $OutDir "COLLECTED_AT$Suffix.txt") -Value "Collected (UTC): $stamp`nCharts: top-playing-now, top-trending, up-and-coming, top-revisited, fun-with-friends (device=all, country=all)`nEndpoints: explore-api get-sort-content, search-api omni-search, games v1 games, game-passes v1 universes/{id}/game-passes, developer-products v2 universes/{id}/developerproducts" -Encoding UTF8
Write-Output "DONE games=$($rows.Count) items=$($items.Count) at $stamp"
