@echo off
set "SCRIPT=%~dp0launch_unity_spike_vulkan.ps1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
