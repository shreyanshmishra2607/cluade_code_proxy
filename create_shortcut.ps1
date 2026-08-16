# create_shortcut.ps1
# Run this once to create a desktop shortcut for Claude Code GUI launcher
# You can then pin that shortcut to your taskbar

$proxyDir = (Get-Content "$env:USERPROFILE\.claude_proxy_path" -Raw -ErrorAction SilentlyContinue).Trim()
if (-not $proxyDir) {
    Write-Host "ERROR: Run install.ps1 first." -ForegroundColor Red
    exit
}

$launcherPath = "$proxyDir\launch_claude.bat"
if (-not (Test-Path $launcherPath)) {
    Write-Host "ERROR: launch_claude.bat not found in $proxyDir" -ForegroundColor Red
    exit
}

# Find Claude's icon from its npm install
$claudeIcon = "$env:APPDATA\npm\node_modules\@anthropic-ai\claude-code\assets\claude-icon.ico"
if (-not (Test-Path $claudeIcon)) {
    $claudeIcon = "shell32.dll,77"  # fallback to a terminal icon
}

# Create desktop shortcut
$desktopPath = [Environment]::GetFolderPath("Desktop")
$shortcutPath = "$desktopPath\Claude Code (Proxy).lnk"

$wsh = New-Object -ComObject WScript.Shell
$shortcut = $wsh.CreateShortcut($shortcutPath)
$shortcut.TargetPath    = $launcherPath
$shortcut.WorkingDirectory = $proxyDir
$shortcut.Description   = "Launch Claude Code via LiteLLM Proxy"
if (Test-Path $claudeIcon) { $shortcut.IconLocation = $claudeIcon }
$shortcut.Save()

Write-Host "Shortcut created: $shortcutPath" -ForegroundColor Green
Write-Host "Right-click it and select 'Pin to taskbar' to add it to your taskbar." -ForegroundColor Cyan
