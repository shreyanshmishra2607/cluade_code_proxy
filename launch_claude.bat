@echo off
setlocal enabledelayedexpansion

REM ================================================
REM  Claude Code GUI Launcher
REM  - Auto-starts proxy if not running
REM  - Reads active model from active_model_id.txt
REM  - Reads API keys from .env
REM  Pin this file's shortcut to your taskbar
REM ================================================

REM Read the proxy folder location from the pointer file
set "POINTER=%USERPROFILE%\.claude_proxy_path"
if not exist "%POINTER%" (
    echo ERROR: Proxy folder not registered.
    echo Run install.ps1 first, then try again.
    pause
    exit /b 1
)
set /p PROXY_DIR=<"%POINTER%"

REM Load API keys from .env into environment
for /f "usebackq tokens=1,* delims==" %%a in ("%PROXY_DIR%\.env") do (
    set "line=%%a"
    if not "!line:~0,1!"=="#" (
        if not "%%a"=="" set "%%a=%%~b"
    )
)

REM Read the active model ID (set by switch-model)
set "MODEL_ID=gpt-4o"
if exist "%PROXY_DIR%\active_model_id.txt" (
    set /p MODEL_ID=<"%PROXY_DIR%\active_model_id.txt"
)

REM Set proxy environment variables
set "ANTHROPIC_BASE_URL=http://127.0.0.1:4000"
set "ANTHROPIC_API_KEY=sk-ant-api03-LOCAL-PROXY-PLACEHOLDER"
set "ANTHROPIC_DEFAULT_SONNET_MODEL=%MODEL_ID%"
set "ANTHROPIC_DEFAULT_OPUS_MODEL=%MODEL_ID%"
set "ANTHROPIC_DEFAULT_HAIKU_MODEL=%MODEL_ID%"
set "PYTHONIOENCODING=utf-8"

REM Check if proxy is already running on port 4000
netstat -an 2>nul | findstr /C:":4000 " >nul 2>&1
if not errorlevel 1 goto :proxy_ready

REM Proxy not running — start it in background (minimized)
echo Starting proxy (%MODEL_ID%)...
start /min "LiteLLM Proxy" litellm --config "%PROXY_DIR%\litellm_config.yaml"

REM Wait up to 20 seconds for proxy to boot
set waited=0
:wait_loop
timeout /t 1 /nobreak >nul
set /a waited+=1
netstat -an 2>nul | findstr /C:":4000 " >nul 2>&1
if not errorlevel 1 goto :proxy_ready
if %waited% lss 20 goto :wait_loop

echo ERROR: Proxy failed to start after 20 seconds.
echo Check: %PROXY_DIR%\proxy_stderr.log
pause
exit /b 1

:proxy_ready
REM Launch Claude Code
powershell -NoProfile -ExecutionPolicy Bypass -Command "& '%APPDATA%\npm\claude.ps1'"
