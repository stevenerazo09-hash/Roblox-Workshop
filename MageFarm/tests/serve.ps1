param([string]$Root, [int]$Port = 8765)
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()
Write-Output "Serving $Root on http://localhost:$Port/"
while ($listener.IsListening) {
    $ctx = $listener.GetContext()
    $res = $ctx.Response
    $res.Headers.Add("Access-Control-Allow-Origin", "*")
    $rel = [System.Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath.TrimStart('/'))
    if ($rel -eq "list") {
        $files = Get-ChildItem $Root -Recurse -File -Filter *.lua | ForEach-Object { $_.FullName.Substring($Root.Length + 1).Replace('\', '/') }
        $bytes = [System.Text.Encoding]::UTF8.GetBytes(($files -join "`n"))
        $res.ContentType = "text/plain; charset=utf-8"
    } else {
        $path = [System.IO.Path]::GetFullPath((Join-Path $Root $rel))
        if (-not $path.StartsWith($Root) -or -not (Test-Path -LiteralPath $path -PathType Leaf)) { $res.StatusCode = 404; $res.Close(); continue }
        $bytes = [System.IO.File]::ReadAllBytes($path)
        if ($path.EndsWith(".html")) { $res.ContentType = "text/html; charset=utf-8" }
        elseif ($path.EndsWith(".png")) { $res.ContentType = "image/png" }
        else { $res.ContentType = "text/plain; charset=utf-8" }
    }
    $res.OutputStream.Write($bytes, 0, $bytes.Length)
    $res.Close()
}