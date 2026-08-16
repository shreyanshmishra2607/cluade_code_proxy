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
$yamlContent = @"
model_list:
  - model_name: "$modelId"
    litellm_params:
      model: "$provider/$modelId"
      api_key: "os.environ/$envKey"
      additional_drop_params: ["reasoning", "reasoning.effort", "reasoning_effort"]

litellm_settings:
  drop_params: true
"@

Set-Content "$configDir\litellm_config.yaml" $yamlContent

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

Write-Host ""
Write-Host "Switched to: $($model.name)" -ForegroundColor Green
Write-Host "Model ID:    $modelId" -ForegroundColor Cyan
Write-Host "Provider:    $provider" -ForegroundColor Cyan
Write-Host ""
Write-Host "Ready! Run 'claudep' to start with the new model." -ForegroundColor Green
