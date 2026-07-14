# uninstall.ps1 - Remove Claude Code Proxy global commands
Write-Host "Removing Claude Code Proxy..." -ForegroundColor Yellow

# Remove pointer file
$pointerFile = "$env:USERPROFILE\.claude_proxy_path"
if (Test-Path $pointerFile) { Remove-Item $pointerFile -Force; Write-Host "  Removed pointer file." -ForegroundColor Green }

# Remove profile block
$profilePath = $PROFILE
if (Test-Path $profilePath) {
    $content = Get-Content $profilePath -Raw
    if ($content.Contains("Claude Code Multi-Model Proxy")) {
        $pattern = '(?s)\r?\n?# === Claude Code Multi-Model Proxy ===.*?# === End Claude Code Multi-Model Proxy ===\r?\n?'
        $cleaned = [regex]::Replace($content, $pattern, '')
        Set-Content $profilePath $cleaned
        Write-Host "  Removed commands from profile." -ForegroundColor Green
    }
}

Write-Host "Done! Restart your terminal." -ForegroundColor Green
