@echo off
chcp 65001 > nul
cd /d C:\Users\david

set LOGDIR=%USERPROFILE%\.claude\skills\global-economy-report\logs
set LOGFILE=%LOGDIR%\daily_report.log
set OUTLOG=%LOGDIR%\daily_report_output.log
if not exist "%LOGDIR%" mkdir "%LOGDIR%"

echo [%date% %time%] Global Economy Report Start >> "%LOGFILE%"

node "%USERPROFILE%\AppData\Roaming\npm\node_modules\@anthropic-ai\claude-code\cli.js" -p "/global-economy-report" --model claude-sonnet-4-6 --allowedTools "WebFetch,WebSearch,Read,Write,Bash,Glob,Grep" >> "%OUTLOG%" 2>&1

if %errorlevel% equ 0 (
    echo [%date% %time%] Success >> "%LOGFILE%"
) else (
    echo [%date% %time%] Failed (errorlevel: %errorlevel%) >> "%LOGFILE%"
)
