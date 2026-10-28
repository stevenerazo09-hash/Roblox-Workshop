# Uploads an FBX to Roblox as a Model asset through Open Cloud and prints the
# result as one JSON line: {"ok":true,"assetId":"123","name":"..."} or
# {"ok":false,"error":"..."}.
#
#   powershell -ExecutionPolicy Bypass -File tools\upload_model.ps1 -File assets\blender\crystal_cluster.fbx -Name "Sandbox Crystal Cluster"
#
# The API key is read from ROBLOX_API_KEY (environment, then .env), falling back
# to MY_API_KEY. It is only ever sent in the x-api-key header: never printed,
# logged or written anywhere.
param(
	[Parameter(Mandatory = $true)][string]$File,
	[Parameter(Mandatory = $true)][string]$Name,
	[string]$Description = "Sandbox asset made in Blender",
	[string]$Username = "lithik260"
)
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Add-Type -AssemblyName System.Net.Http
$root = Split-Path $PSScriptRoot -Parent

function Read-DotEnv([string]$key) {
	$envFile = Join-Path $root ".env"
	if (-not (Test-Path $envFile)) { return $null }
	foreach ($line in Get-Content $envFile) {
		if ($line -match "^\s*$key\s*=\s*(.+?)\s*$") { return $Matches[1] }
	}
	return $null
}

function Done($obj) { $obj | ConvertTo-Json -Compress; exit 0 }

$apiKey = $env:ROBLOX_API_KEY
if (-not $apiKey) { $apiKey = Read-DotEnv "ROBLOX_API_KEY" }
if (-not $apiKey) { $apiKey = $env:MY_API_KEY }
if (-not $apiKey) { Done @{ ok = $false; error = "No API key: set ROBLOX_API_KEY in .env or the environment" } }

$path = (Resolve-Path (Join-Path $root $File) -ErrorAction SilentlyContinue)
if (-not $path) { $path = Resolve-Path $File }
$path = $path.Path

# Creator user id
$userId = $env:ROBLOX_USER_ID
if (-not $userId) { $userId = Read-DotEnv "ROBLOX_USER_ID" }
if (-not $userId) {
	$lookup = Invoke-RestMethod -Method Post -Uri "https://users.roblox.com/v1/usernames/users" -ContentType "application/json" -Body (@{ usernames = @($Username); excludeBannedUsers = $true } | ConvertTo-Json)
	$userId = [string]$lookup.data[0].id
}

$client = New-Object System.Net.Http.HttpClient
$client.Timeout = [TimeSpan]::FromSeconds(120)
$client.DefaultRequestHeaders.Add("x-api-key", $apiKey)
$apiKey = $null

$request = @{
	assetType = "Model"
	displayName = $Name
	description = $Description
	creationContext = @{ creator = @{ userId = $userId } }
} | ConvertTo-Json -Depth 5 -Compress

$form = New-Object System.Net.Http.MultipartFormDataContent
$form.Add((New-Object System.Net.Http.StringContent($request, [Text.Encoding]::UTF8, "application/json")), "request")
$bytes = [System.IO.File]::ReadAllBytes($path)
$filePart = New-Object System.Net.Http.ByteArrayContent(, $bytes)
$filePart.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse("model/fbx")
$form.Add($filePart, "fileContent", [System.IO.Path]::GetFileName($path))

$resp = $client.PostAsync("https://apis.roblox.com/assets/v1/assets", $form).Result
$body = $resp.Content.ReadAsStringAsync().Result
if (-not $resp.IsSuccessStatusCode) { Done @{ ok = $false; error = "upload HTTP $([int]$resp.StatusCode): $body" } }
$op = $body | ConvertFrom-Json

# Poll the long-running operation until Roblox has processed the model
$opPath = $op.path
for ($i = 0; $i -lt 40; $i++) {
	if ($op.done -and $op.response) { break }
	Start-Sleep -Seconds 3
	$r = $client.GetAsync("https://apis.roblox.com/assets/v1/$opPath").Result
	$b = $r.Content.ReadAsStringAsync().Result
	if (-not $r.IsSuccessStatusCode) { Done @{ ok = $false; error = "poll HTTP $([int]$r.StatusCode): $b" } }
	$op = $b | ConvertFrom-Json
}
if (-not $op.done) { Done @{ ok = $false; error = "timed out waiting for $opPath" } }
if ($op.error) { Done @{ ok = $false; error = ($op.error | ConvertTo-Json -Compress) } }
$assetId = [string]$op.response.assetId
$state = $op.response.moderationResult.moderationState
Done @{ ok = $true; assetId = $assetId; name = $Name; moderation = $state }
