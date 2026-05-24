@echo off
set "SCRIPT=%~dp0build_unity_spike_player_windows.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
pause
