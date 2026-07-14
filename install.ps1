# install.ps1 - One-time setup for Claude Code Multi-Model Proxy
# Run this after cloning: .\install.ps1

$proxyDir = $PSScriptRoot
$pointerFile = "$env:USERPROFILE\.claude_proxy_path"
$profilePath = $PROFILE

Write-Host ""
Write-Host "  Claude Code Multi-Model Proxy - Installer" -ForegroundColor Cyan
Write-Host "  ==========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check prerequisites
Write-Host "[1/4] Checking prerequisites..." -ForegroundColor Yellow
$missing = @()
if (-not (Get-Command litellm -ErrorAction SilentlyContinue)) { $missing += "litellm (pip install litellm)" }
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    $claudePath = "C:\Users\$env:USERNAME\AppData\Roaming\npm\claude.ps1"
    if (-not (Test-Path $claudePath)) { $missing += "claude-code (npm install -g @anthropic-ai/claude-code)" }
}
if ($missing.Count -gt 0) {
    Write-Host "  Missing dependencies:" -ForegroundColor Red
    $missing | ForEach-Object { Write-Host "    - $_" -ForegroundColor Red }
    Write-Host ""
    $continue = Read-Host "Continue anyway? (y/n)"
    if ($continue -ne "y") { return }
} else {
    Write-Host "  All prerequisites found!" -ForegroundColor Green
}

# Step 2: Register the proxy folder
Write-Host "[2/4] Registering proxy folder..." -ForegroundColor Yellow
Set-Content $pointerFile $proxyDir
Write-Host "  Saved: $pointerFile -> $proxyDir" -ForegroundColor Green

# Step 3: Create .env if missing
Write-Host "[3/4] Setting up API keys..." -ForegroundColor Yellow
if (-not (Test-Path "$proxyDir\.env")) {
    Write-Host "  No .env file found. Let's set up your first model." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Available free-tier providers:" -ForegroundColor Cyan
    Write-Host "    1. NVIDIA NIM  (https://build.nvidia.com)" -ForegroundColor White
    Write-Host "    2. Groq        (https://console.groq.com)" -ForegroundColor White
    Write-Host "    3. Gemini      (https://aistudio.google.com)" -ForegroundColor White
    Write-Host ""
    $choice = Read-Host "  Pick a provider (1/2/3) or press Enter to skip"

    switch ($choice) {
        "1" { $envKey = "NVIDIA_API_KEY"; $model = "nvidia" }
        "2" { $envKey = "GROQ_API_KEY"; $model = "groq" }
        "3" { $envKey = "GEMINI_API_KEY"; $model = "gemini" }
        default { $envKey = $null }
    }

    if ($envKey) {
        $apiKey = Read-Host "  Paste your $envKey"
        Set-Content "$proxyDir\.env" "$envKey=`"$apiKey`""
        Set-Content "$proxyDir\active_model.txt" $model
        Write-Host "  Key saved! Active model: $model" -ForegroundColor Green

        # Generate litellm_config.yaml for chosen model
        $modelsJson = Get-Content "$proxyDir\models.json" | ConvertFrom-Json
        $m = $modelsJson.$model
        $yamlContent = @"
model_list:
  - model_name: "$($m.model_id)"
    litellm_params:
      model: "$($m.litellm_provider)/$($m.model_id)"
      api_key: "os.environ/$($m.env_key)"

litellm_settings:
  drop_params: true
"@
        Set-Content "$proxyDir\litellm_config.yaml" $yamlContent
    } else {
        Set-Content "$proxyDir\.env" "# Add your API keys here, e.g.:`n# NVIDIA_API_KEY=`"your-key-here`""
        Write-Host "  Skipped. Add keys to .env manually later." -ForegroundColor Yellow
    }
} else {
    Write-Host "  .env already exists. Skipping." -ForegroundColor Green
}

# Step 4: Install PowerShell profile functions
Write-Host "[4/4] Installing global commands (claudep, switch-model, claudep-setup)..." -ForegroundColor Yellow

$profileBlock = @'

# === Claude Code Multi-Model Proxy ===
$configPointer = "$env:USERPROFILE\.claude_proxy_path"
if (Test-Path $configPointer) { $global:ClaudeConfigDir = (Get-Content $configPointer -Raw).Trim() }
else { $global:ClaudeConfigDir = $null }

function switch-model {
    param([string]$ModelName)
    if (-not $global:ClaudeConfigDir) { Write-Host "Run 'claudep-setup' first." -ForegroundColor Red; return }
    & "$global:ClaudeConfigDir\switch_model.ps1" $ModelName
}

function claudep-setup {
    param([string]$Path)
    if (-not $Path) { $Path = Get-Location }
    if (-not (Test-Path "$Path\models.json")) { Write-Host "Not a valid proxy folder." -ForegroundColor Red; return }
    Set-Content "$env:USERPROFILE\.claude_proxy_path" $Path
    $global:ClaudeConfigDir = "$Path"
    Write-Host "Registered: $Path" -ForegroundColor Green
}

function claudep {
    if (-not $global:ClaudeConfigDir) { Write-Host "Run 'claudep-setup' in your proxy folder first." -ForegroundColor Red; return }
    $env:ANTHROPIC_BASE_URL="http://127.0.0.1:4000"
    $env:ANTHROPIC_API_KEY="sk-ant-api03-LOCAL-PROXY-PLACEHOLDER"
    $env:PYTHONIOENCODING="utf-8"
    $activeModel = Get-Content "$global:ClaudeConfigDir\active_model.txt" -ErrorAction SilentlyContinue
    if (-not $activeModel) { $activeModel = "nvidia" }
    $modelsJson = Get-Content "$global:ClaudeConfigDir\models.json" | ConvertFrom-Json
    if ($modelsJson.$activeModel) { $modelId = $modelsJson.$activeModel.model_id } else { $modelId = $activeModel }
    $env:ANTHROPIC_DEFAULT_SONNET_MODEL=$modelId
    $env:ANTHROPIC_DEFAULT_OPUS_MODEL=$modelId
    $env:ANTHROPIC_DEFAULT_HAIKU_MODEL=$modelId
    $connection = Get-NetTCPConnection -LocalPort 4000 -ErrorAction SilentlyContinue
    if (-not $connection) {
        Write-Host "Starting proxy ($modelId)..." -ForegroundColor Yellow
        Get-Content "$global:ClaudeConfigDir\.env" | Where-Object { $_ -match '=' -and $_ -notmatch '^\s*#' } | ForEach-Object {
            $k, $v = $_.Split('=', 2); [Environment]::SetEnvironmentVariable($k, $v.Trim('"'), "Process")
        }
        $script:proxyProcess = Start-Process -NoNewWindow -PassThru -FilePath litellm -ArgumentList "--config `"$global:ClaudeConfigDir\litellm_config.yaml`"" -RedirectStandardOutput "$global:ClaudeConfigDir\proxy_stdout.log" -RedirectStandardError "$global:ClaudeConfigDir\proxy_stderr.log"
        Write-Host "Waiting for proxy..." -ForegroundColor Yellow
        $maxWait = 15; $waited = 0
        while ($waited -lt $maxWait) {
            Start-Sleep -Seconds 1; $waited++
            if (Get-NetTCPConnection -LocalPort 4000 -ErrorAction SilentlyContinue) { Write-Host "Proxy UP! (${waited}s)" -ForegroundColor Green; break }
        }
        if ($waited -ge $maxWait) { Write-Host "Proxy failed to start." -ForegroundColor Red; return }
    }
    & "C:\Users\$env:USERNAME\AppData\Roaming\npm\claude.ps1" @args
    if ($script:proxyProcess -and !$script:proxyProcess.HasExited) {
        Write-Host "`nShutting down proxy..." -ForegroundColor Yellow
        $script:proxyProcess | Stop-Process -Force -ErrorAction SilentlyContinue
        Write-Host "Proxy stopped." -ForegroundColor Green
    }
}
# === End Claude Code Multi-Model Proxy ===
'@

# Check if profile exists and if our block is already there
if (-not (Test-Path $profilePath)) {
    New-Item -ItemType File -Force -Path $profilePath | Out-Null
    Write-Host "  Created new profile: $profilePath" -ForegroundColor Cyan
}

$existingProfile = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
if ($existingProfile -and $existingProfile.Contains("Claude Code Multi-Model Proxy")) {
    # Remove old block and replace
    $pattern = '(?s)# === Claude Code Multi-Model Proxy ===.*?# === End Claude Code Multi-Model Proxy ==='
    $newProfile = [regex]::Replace($existingProfile, $pattern, $profileBlock.Trim())
    Set-Content $profilePath $newProfile
    Write-Host "  Updated existing profile block." -ForegroundColor Green
} else {
    Add-Content $profilePath $profileBlock
    Write-Host "  Added commands to profile." -ForegroundColor Green
}

Write-Host ""
Write-Host "  Setup complete!" -ForegroundColor Green
Write-Host "  ===============" -ForegroundColor Green
Write-Host ""
Write-Host "  Close this terminal, open a new one, and type:" -ForegroundColor Cyan
Write-Host "    claudep" -ForegroundColor White
Write-Host ""
