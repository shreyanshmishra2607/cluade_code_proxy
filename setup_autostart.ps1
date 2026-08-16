# setup_autostart.ps1
# Registers the LiteLLM proxy as a Windows Task Scheduler task
# so the proxy auto-starts on login — no terminal needed for VS Code extension to work
# Run once: .\setup_autostart.ps1

$configPointer = "$env:USERPROFILE\.claude_proxy_path"
if (-not (Test-Path $configPointer)) {
    Write-Host "ERROR: Run install.ps1 first to register the proxy folder." -ForegroundColor Red
    exit
}
$proxyDir = (Get-Content $configPointer -Raw).Trim()
$litellmPath = (Get-Command litellm -ErrorAction SilentlyContinue)?.Source
if (-not $litellmPath) {
    # Try common pip install locations
    $litellmPath = "$env:LOCALAPPDATA\Programs\Python\Python3*\Scripts\litellm.exe"
    $litellmPath = (Resolve-Path $litellmPath -ErrorAction SilentlyContinue) | Select-Object -First 1 -ExpandProperty Path
}
if (-not $litellmPath) { $litellmPath = "litellm" }

$taskName = "ClaudeCodeProxy"
$action = New-ScheduledTaskAction `
    -Execute "litellm" `
    -Argument "--config `"$proxyDir\litellm_config.yaml`"" `
    -WorkingDirectory $proxyDir

$trigger  = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$settings = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit (New-TimeSpan -Hours 0) `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 1) `
    -StartWhenAvailable

# Remove existing task if any
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

Register-ScheduledTask `
    -TaskName $taskName `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Description "Auto-starts LiteLLM proxy for Claude Code VS Code extension" `
    -RunLevel Limited | Out-Null

Write-Host ""
Write-Host "Auto-start task registered: '$taskName'" -ForegroundColor Green
Write-Host "The proxy will start automatically every time you log into Windows." -ForegroundColor Cyan
Write-Host ""
Write-Host "Starting proxy now for this session..." -ForegroundColor Yellow
Start-ScheduledTask -TaskName $taskName
Start-Sleep -Seconds 3

$running = Get-NetTCPConnection -LocalPort 4000 -ErrorAction SilentlyContinue
if ($running) {
    Write-Host "Proxy is UP on port 4000!" -ForegroundColor Green
} else {
    Write-Host "Proxy is starting in background (may take ~12s on first boot)." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor White
Write-Host "  1. Restart VS Code" -ForegroundColor Cyan
Write-Host "  2. Open the Claude Code extension" -ForegroundColor Cyan
Write-Host "  3. It should connect without asking you to log in!" -ForegroundColor Cyan
Write-Host ""
Write-Host "To remove auto-start later, run: Unregister-ScheduledTask -TaskName '$taskName' -Confirm:`$false" -ForegroundColor Gray
