# Minimal static file server for this folder: http://localhost:8080
param([int]$Port = 8080)

$root = $PSScriptRoot
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()
Write-Host "Serving $root at http://localhost:$Port/"

$types = @{
  '.html' = 'text/html; charset=utf-8'; '.css' = 'text/css'; '.js' = 'application/javascript'
  '.png' = 'image/png'; '.jpg' = 'image/jpeg'; '.svg' = 'image/svg+xml'; '.ico' = 'image/x-icon'
}

while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  $path = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath.TrimStart('/'))
  if ($path -eq '') { $path = 'index.html' }
  $file = [IO.Path]::GetFullPath((Join-Path $root $path))
  $res = $ctx.Response
  if ($file.StartsWith($root) -and (Test-Path $file -PathType Leaf)) {
    $bytes = [IO.File]::ReadAllBytes($file)
    $ext = [IO.Path]::GetExtension($file).ToLower()
    $res.ContentType = if ($types[$ext]) { $types[$ext] } else { 'application/octet-stream' }
    $res.ContentLength64 = $bytes.Length
    if ($ctx.Request.HttpMethod -ne 'HEAD') {
      try { $res.OutputStream.Write($bytes, 0, $bytes.Length) } catch {}
    }
  } else {
    $res.StatusCode = 404
  }
  $res.Close()
  Write-Host "$($ctx.Request.HttpMethod) /$path -> $($res.StatusCode)"
}
