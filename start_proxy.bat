@echo off
set PYTHONIOENCODING=utf-8
set "configDir=%~dp0"
for /f "usebackq tokens=1,* delims==" %%a in ("%configDir%.env") do set "%%a=%%~b"
cd /d "%configDir%"
litellm --config litellm_config.yaml
