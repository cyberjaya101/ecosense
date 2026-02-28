@echo off
title EcoSense Complete Demo Environment
color 0A
setlocal

:: Function to check if a process is running on a port and kill it
:: We need to ensure port 8080 (or whatever AI Brain uses) isn't lingering
echo [System] Cleaning up existing node processes...
taskkill /F /IM node.exe >nul 2>&1

:: Move to backend folder
cd /d "%~dp0..\backend"

echo [System] Starting EcoSense AI Brain...
:: Start the node server in a separate window so it runs concurrently
start "EcoSense AI Brain (Node.js)" cmd /c "node ai_brain.js"

:: Wait a moment for it to initialize
timeout /t 3 > nul

:MENU
cls
echo ===============================================================================
echo                ECOSENSE DEMO COMMAND CENTER (KITAHACK 2026)
echo ===============================================================================
echo.
echo Make sure your Flutter emulator is running and focused!
echo.
echo [1] Initialize Normal Campus Day (Green Status)
echo [2] Trigger Heatwave Sequence (Server Loads Peak)
echo [3] Trigger Monsoon Sequence (Excessive AC Coasting)
echo [4] Inject Student Qualitative Feedback (Points Demo)
echo [5] Trigger "Ghost Room" Incident (High Value Anomaly)
echo.
echo [0] EXIT and Tear Down Environment
echo.
echo ===============================================================================

set /p choice="Enter scenario number: "

if "%choice%"=="1" goto NORMAL
if "%choice%"=="2" goto HEATWAVE
if "%choice%"=="3" goto MONSOON
if "%choice%"=="4" goto FEEDBACK
if "%choice%"=="5" goto GHOST
if "%choice%"=="0" goto EXIT
goto MENU

:NORMAL
echo.
echo [Action] Generating 'Normal' weather dataset...
python generate_dataset.py Normal
echo [Result] Campus initialized. Check Map for 'OPTIMAL' green dots.
timeout /t 3 > nul
goto MENU

:HEATWAVE
echo.
echo [Action] Triggering Heatwave anomaly...
python generate_dataset.py Heatwave
echo [Result] Engineering building temp spiking. Check Admin Map for Alerts!
timeout /t 3 > nul
goto MENU

:MONSOON
echo.
echo [Action] Triggering Monsoon anomaly...
python generate_dataset.py Monsoon
echo [Result] Exam Hall cooling too aggressively. Check Admin Map for Alerts!
timeout /t 3 > nul
goto MENU

:FEEDBACK
echo.
echo [Action] Injecting Student Feedback...
set /p room_id="(1) Enter Room ID (e.g., DK1, Lounge, Examination Hall): "
set /p comment="(2) Enter Comment (e.g., It's freezing in here!): "
python generate_dataset.py feedback "%room_id%" TOO_COLD "%comment%"
echo [Result] Feedback injected! The AI Brain will now evaluate the qualitative report.
timeout /t 3 > nul
goto MENU

:GHOST
echo.
echo [Action] Triggering Ghost Room Incident...
set /p room_id="(1) Enter Room ID to haunt (e.g., Lounge): "
python generate_dataset.py ghost "%room_id%"
echo [Result] Ghost Room created! Check Admin Map for RED critical anomaly.
timeout /t 3 > nul
goto MENU

:EXIT
echo.
echo [System] Tearing down environment...
taskkill /FI "WINDOWTITLE eq EcoSense AI Brain (Node.js)*" /T /F >nul 2>&1
echo [System] Goodbye!
timeout /t 2 > nul
exit

