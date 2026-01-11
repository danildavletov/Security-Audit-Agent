@echo off
REM Security Audit via Claude (Windows CMD)
REM Usage: security_audit.bat <ssh_host>

if "%~1"=="" (
    echo Usage: %~nx0 ^<ssh_host^>
    echo Example: %~nx0 servername
    exit /b 1
)

set HOST=%~1
set SCRIPT_DIR=%~dp0

echo Collecting security data from %HOST%...
ssh %HOST% "bash -s" < "%SCRIPT_DIR%security_checkup.sh" > "%TEMP%\audit_output.txt" 2>&1

if errorlevel 1 (
    echo SSH connection failed
    exit /b 1
)

echo Analyzing with Claude...
powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%security_audit.ps1" %HOST%
