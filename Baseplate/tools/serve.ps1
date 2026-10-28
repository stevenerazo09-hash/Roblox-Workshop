# Serves the project folder over http://localhost so the Roblox Studio MCP
# (upload_image) can fetch generated images from assets/images.
#   powershell -ExecutionPolicy Bypass -File tools\serve.ps1
param([string]$Root = (Split-Path $PSScriptRoot -Parent), [int]$Port = 8766)
$Root = (Resolve-Path $Root).Path
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()
Write-Output "Serving $Root on http://localhost:$Port/"
while ($listener.IsListening) {
	$ctx = $listener.GetContext()
	$res = $ctx.Response
	$rel = [System.Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath.TrimStart('/'))
	$path = [System.IO.Path]::GetFullPath((Join-Path $Root $rel))
	# Only files under assets/ are served, and never .env
	$assets = Join-Path $Root "assets"
	if (-not $path.StartsWith($assets) -or -not (Test-Path -LiteralPath $path -PathType Leaf)) {
		$res.StatusCode = 404
		$res.Close()
		continue
	}
	$bytes = [System.IO.File]::ReadAllBytes($path)
	if ($path.EndsWith(".png")) { $res.ContentType = "image/png" }
	elseif ($path.EndsWith(".jpg")) { $res.ContentType = "image/jpeg" }
	else { $res.ContentType = "application/octet-stream" }
	$res.OutputStream.Write($bytes, 0, $bytes.Length)
	$res.Close()
}
