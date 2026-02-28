@echo off
title EcoSense AI Brain Teardown
echo [System] Terminating all EcoSense Node processes...
taskkill /FI "WINDOWTITLE eq EcoSense AI Brain (Node.js)*" /T /F >nul 2>&1
taskkill /F /IM node.exe >nul 2>&1
echo [System] Teardown complete.
pause
