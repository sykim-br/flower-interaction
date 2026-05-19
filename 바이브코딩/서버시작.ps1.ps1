# 간단한 로컬 HTTP 서버 (포트 8080)
$port = 8080
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  서버 시작! 아래 주소를 크롬에서 열어주세요:" -ForegroundColor Green
Write-Host ""
Write-Host "  http://localhost:$port/" -ForegroundColor Yellow
Write-Host ""
Write-Host "  종료하려면 Ctrl+C 를 누르세요" -ForegroundColor Gray
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

$mimeTypes = @{
    '.html' = 'text/html; charset=utf-8'
    '.js'   = 'application/javascript'
    '.css'  = 'text/css'
    '.mp4'  = 'video/mp4'
    '.jpg'  = 'image/jpeg'
    '.png'  = 'image/png'
    '.ico'  = 'image/x-icon'
}

while ($listener.IsListening) {
    $context  = $listener.GetContext()
    $request  = $context.Request
    $response = $context.Response

    $urlPath = $request.Url.LocalPath
    if ($urlPath -eq '/') { $urlPath = '/index.html' }

    $filePath = Join-Path $root ($urlPath.TrimStart('/'))

    if (Test-Path $filePath -PathType Leaf) {
        $ext  = [System.IO.Path]::GetExtension($filePath).ToLower()
        $mime = if ($mimeTypes[$ext]) { $mimeTypes[$ext] } else { 'application/octet-stream' }

        $bytes = [System.IO.File]::ReadAllBytes($filePath)
        $response.ContentType   = $mime
        $response.ContentLength64 = $bytes.Length

        # 비디오 파일 Range 요청 지원
        if ($mime -eq 'video/mp4') {
            $response.Headers.Add('Accept-Ranges', 'bytes')
        }

        $response.OutputStream.Write($bytes, 0, $bytes.Length)
        Write-Host "200 $urlPath" -ForegroundColor DarkGray
    } else {
        $response.StatusCode = 404
        $body = [System.Text.Encoding]::UTF8.GetBytes("Not Found: $urlPath")
        $response.OutputStream.Write($body, 0, $body.Length)
        Write-Host "404 $urlPath" -ForegroundColor Red
    }

    $response.OutputStream.Close()
}
