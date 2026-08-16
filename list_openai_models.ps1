# list_openai_models.ps1 - Lists available OpenAI models for the API key in .env

$configDir = $PSScriptRoot
$envFile = "$configDir\.env"

if (-not (Test-Path $envFile)) {
    Write-Host "Error: .env file not found at $envFile" -ForegroundColor Red
    return
}

# Find and parse OPENAI_API_KEY from .env
$envContent = Get-Content $envFile
$apiKeyLine = $envContent | Where-Object { $_ -match "^OPENAI_API_KEY=" }

if (-not $apiKeyLine) {
    Write-Host "Error: OPENAI_API_KEY not found in .env" -ForegroundColor Red
    return
}

# Extract key (handling quotes if present)
$apiKey = ($apiKeyLine -split '=', 2)[1].Trim().Trim('"').Trim("'")

if ([string]::IsNullOrWhiteSpace($apiKey)) {
    Write-Host "Error: OPENAI_API_KEY is empty in .env" -ForegroundColor Red
    return
}

Write-Host "Fetching available OpenAI models..." -ForegroundColor Yellow

try {
    $headers = @{
        "Authorization" = "Bearer $apiKey"
    }
    $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/models" -Headers $headers -Method Get
    
    if ($response -and $response.data) {
        $models = $response.data | Sort-Object id
        Write-Host "Found $($models.Count) models:" -ForegroundColor Green
        Write-Host "------------------------" -ForegroundColor Gray
        foreach ($model in $models) {
            Write-Host $model.id -ForegroundColor Cyan
        }
    } else {
        Write-Host "No models returned from API." -ForegroundColor Yellow
    }
}
catch {
    Write-Host "Error calling OpenAI API:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    if ($_.ErrorDetails) {
        Write-Host $_.ErrorDetails.Message -ForegroundColor Red
    }
}
