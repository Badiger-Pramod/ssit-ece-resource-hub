# Lightweight static web server for SSIT ECE Resource Hub
$port = 8080
$prefix = "http://localhost:$port/"
$baseDir = $PSScriptRoot

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)
try {
    $listener.Start()
    Write-Host "SSIT ECE Resource Hub is live at $prefix"
} catch {
    Write-Host "Could not bind to port $port : $_"
    exit 1
}

while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $path = $request.Url.LocalPath.TrimStart('/').Replace('/', [System.IO.Path]::DirectorySeparatorChar)
        if ([string]::IsNullOrWhiteSpace($path)) {
            $path = "index.html"
        }
        $fullPath = Join-Path $baseDir $path

        if (Test-Path $fullPath -PathType Leaf) {
            $bytes = [System.IO.File]::ReadAllBytes($fullPath)
            $ext = [System.IO.Path]::GetExtension($fullPath).ToLower()
            $contentType = switch ($ext) {
                ".html" { "text/html; charset=utf-8" }
                ".css"  { "text/css; charset=utf-8" }
                ".js"   { "application/javascript; charset=utf-8" }
                ".svg"  { "image/svg+xml" }
                ".jpg"  { "image/jpeg" }
                ".jpeg" { "image/jpeg" }
                ".png"  { "image/png" }
                ".webp" { "image/webp" }
                ".xml"  { "application/xml; charset=utf-8" }
                ".txt"  { "text/plain; charset=utf-8" }
                default { "application/octet-stream" }
            }
            $response.ContentType = $contentType
            $response.ContentLength64 = $bytes.Length
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $response.StatusCode = 404
            $errMsg = [System.Text.Encoding]::UTF8.GetBytes("404 File Not Found")
            $response.ContentLength64 = $errMsg.Length
            $response.OutputStream.Write($errMsg, 0, $errMsg.Length)
        }
        $response.OutputStream.Close()
    } catch {
        # continue loop
    }
}
