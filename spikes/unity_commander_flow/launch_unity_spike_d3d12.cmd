@echo off
set "SCRIPT=%~dp0launch_unity_spike_d3d12.ps1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
