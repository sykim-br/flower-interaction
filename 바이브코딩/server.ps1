$port = 8080
$root = "C:\Users\" + [char]0xAE40 + [char]0xC11C + [char]0xC724 + "\Desktop\" + [char]0xBC14 + [char]0xC774 + [char]0xBE0C + [char]0xCF54 + [char]0xB529

$root = Split-Path -Parent $MyInvocation.MyCommand.Path

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:" + $port + "/")
$listener.Start()

Write-Host "Server running at http://localhost:$port/" -ForegroundColor Green
Write-Host "Press Ctrl+C to stop." -ForegroundColor Gray

$mimeTypes = @{
    ".html" = "text/html; charset=utf-8"
    ".js"   = "application/javascript"
    ".css"  = "text/css"
    ".mp4"  = "video/mp4"
    ".jpg"  = "image/jpeg"
    ".png"  = "image/png"
}

while ($listener.IsListening) {
    $context  = $listener.GetContext()
    $request  = $context.Request
    $response = $context.Response

    $urlPath = $request.Url.LocalPath
    if ($urlPath -eq "/") { $urlPath = "/index.html" }

    $filePath = Join-Path $root ($urlPath.TrimStart("/"))

    if (Test-Path $filePath -PathType Leaf) {
        $ext  = [System.IO.Path]::GetExtension($filePath).ToLower()
        $mime = if ($mimeTypes[$ext]) { $mimeTypes[$ext] } else { "application/octet-stream" }
        $bytes = [System.IO.File]::ReadAllBytes($filePath)
        $response.ContentType = $mime
        $response.ContentLength64 = $bytes.Length
        if ($mime -eq "video/mp4") { $response.Headers.Add("Accept-Ranges", "bytes") }
        $response.OutputStream.Write($bytes, 0, $bytes.Length)
        Write-Host "200 $urlPath"
    } else {
        $response.StatusCode = 404
        $body = [System.Text.Encoding]::UTF8.GetBytes("Not Found")
        $response.OutputStream.Write($body, 0, $body.Length)
    }
    $response.OutputStream.Close()
}
