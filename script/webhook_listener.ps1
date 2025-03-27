$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://*:5000/webhook/")
$listener.Start()

$GITHUB_SECRET = "sua_chave_secreta"
$REPO_DIR = "C:\Users\felip\Filipinho\github_actions"
$EXECUTABLE_PATH = "$REPO_DIR\out\http.exe"

Write-Host "Webhook listener running..."

while ($true) {
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response

    try {
        if ($request.HttpMethod -eq "POST" -and $request.Url.LocalPath -eq "/webhook") {
            $signature = $request.Headers["X-Hub-Signature-256"]
            $body = (New-Object System.IO.StreamReader $request.InputStream).ReadToEnd()
            
            $hmac = New-Object System.Security.Cryptography.HMACSHA256
            $hmac.Key = [Text.Encoding]::ASCII.GetBytes($GITHUB_SECRET)
            $computedHash = "sha256=" + [BitConverter]::ToString($hmac.ComputeHash([Text.Encoding]::ASCII.GetBytes($body)) -replace '-',''
            
            if ($signature -eq $computedHash) {
                Set-Location $REPO_DIR
                
                Stop-Process -Name "http" -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 2
                
                if (Test-Path "out") {
                    Remove-Item -Recurse -Force "out"
                }
                
                $latestRelease = (Invoke-RestMethod "https://api.github.com/repos/FelipeSoft/github_actions/releases/latest").assets[0]
                Invoke-WebRequest $latestRelease.browser_download_url -OutFile "http.exe"
                
                Start-Process -FilePath $EXECUTABLE_PATH -WindowStyle Hidden
                
                $response.StatusCode = 200
                $message = "Update applied successfully"
            } else {
                $response.StatusCode = 403
                $message = "Invalid signature"
            }
        } else {
            $response.StatusCode = 404
            $message = "Endpoint not found"
        }
    } catch {
        $response.StatusCode = 500
        $message = "Internal error: $_"
    }

    $buffer = [System.Text.Encoding]::UTF8.GetBytes($message)
    $response.ContentLength64 = $buffer.Length
    $output = $response.OutputStream
    $output.Write($buffer, 0, $buffer.Length)
    $output.Close()
}