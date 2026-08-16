# switch_model.ps1 - Switches the active model for Claude Code
# Usage: .\switch_model.ps1 nvidia | gemini | gpt | groq | deepseek | mistral

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$ModelName,

    [Parameter(Mandatory=$false, Position=1)]
    [string]$CustomModelId
)

$configDir = $PSScriptRoot
$modelsJson = Get-Content "$configDir\models.json" | ConvertFrom-Json

if (-not $modelsJson.$ModelName) {
    Write-Host "Unknown model: $ModelName" -ForegroundColor Red
    Write-Host "Available models:" -ForegroundColor Yellow
    $modelsJson.PSObject.Properties | ForEach-Object {
        Write-Host "  $($_.Name) - $($_.Value.name)" -ForegroundColor Cyan
    }
    return
}

$model = $modelsJson.$ModelName
$envKey = $model.env_key
$provider = $model.litellm_provider
$modelId = $model.model_id

if ($CustomModelId) {
    $modelId = $CustomModelId
}

# Check if API key exists in .env
$envContent = Get-Content "$configDir\.env" -ErrorAction SilentlyContinue
$hasKey = $envContent | Where-Object { $_ -match "^$envKey=" }

if (-not $hasKey) {
    Write-Host "API key for $($model.name) not found in .env" -ForegroundColor Red
    $key = Read-Host "Enter your $envKey"
    Add-Content "$configDir\.env" "`n$envKey=`"$key`""
    Write-Host "Key saved to .env" -ForegroundColor Green
}

# Generate litellm_config.yaml
# Includes Claude model name aliases so the VS Code extension works too
# (The extension sends claude-opus-5, claude-sonnet-4-5, etc. regardless of env vars)
$litellmParams = @"
      model: "$provider/$modelId"
      api_key: "os.environ/$envKey"
      additional_drop_params: ["reasoning", "reasoning.effort", "reasoning_effort"]
"@

$claudeAliases = @(
    "claude-opus-5", "claude-opus-4",
    "claude-sonnet-4-5", "claude-sonnet-4",
    "claude-haiku-4",
    "claude-3-5-sonnet-20241022", "claude-3-5-sonnet-latest",
    "claude-3-5-haiku-20241022",  "claude-3-5-haiku-latest",
    "claude-3-opus-20240229",     "claude-3-opus-latest",
    "claude-3-sonnet-20240229",   "claude-3-haiku-20240307"
)

$aliasEntries = ($claudeAliases | ForEach-Object {
    "  - model_name: `"$_`"`n    litellm_params:`n$litellmParams"
}) -join "`n"

$yamlContent = @"
model_list:
  - model_name: "$modelId"
    litellm_params:
$litellmParams
$aliasEntries

litellm_settings:
  drop_params: true
"@

Set-Content "$configDir\litellm_config.yaml" $yamlContent

# Terminate old proxy instance so next run loads fresh config
Stop-Process -Name litellm -Force -ErrorAction SilentlyContinue

# Generate start_proxy.bat
$batContent = @"
@echo off
set PYTHONIOENCODING=utf-8
set `"configDir=%~dp0`"
for /f `"usebackq tokens=1,* delims==`" %%a in (`"%configDir%.env`") do set `"%%a=%%~b`"
cd /d `"%configDir%`"
litellm --config litellm_config.yaml
"@

Set-Content "$configDir\start_proxy.bat" $batContent

# Save provider key (e.g. "gpt") and the actual resolved model ID separately
Set-Content "$configDir\active_model.txt" $ModelName
Set-Content "$configDir\active_model_id.txt" $modelId

# Persist env vars at USER level so VS Code extension (and any GUI app) picks them up
# without needing a terminal session
[Environment]::SetEnvironmentVariable("ANTHROPIC_BASE_URL",              "http://127.0.0.1:4000",                   "User")
[Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY",               "sk-ant-api03-LOCAL-PROXY-PLACEHOLDER",    "User")
[Environment]::SetEnvironmentVariable("ANTHROPIC_DEFAULT_SONNET_MODEL",  $modelId,                                  "User")
[Environment]::SetEnvironmentVariable("ANTHROPIC_DEFAULT_OPUS_MODEL",    $modelId,                                  "User")
[Environment]::SetEnvironmentVariable("ANTHROPIC_DEFAULT_HAIKU_MODEL",   $modelId,                                  "User")

Write-Host ""
Write-Host "Switched to: $($model.name)" -ForegroundColor Green
Write-Host "Model ID:    $modelId" -ForegroundColor Cyan
Write-Host "Provider:    $provider" -ForegroundColor Cyan
Write-Host ""
Write-Host "Ready! Run 'claudep' or open VS Code - proxy env vars updated globally." -ForegroundColor Green
