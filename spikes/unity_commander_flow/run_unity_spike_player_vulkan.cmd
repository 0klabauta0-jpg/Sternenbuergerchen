@echo off
set "EXE=%~dp0Builds\Windows\SternenBuergerchenUnitySpike.exe"
if not exist "%EXE%" (
  echo Player build not found:
  echo %EXE%
  echo Run build_unity_spike_player_windows.cmd first.
  pause
  exit /b 1
)
start "" "%EXE%" -force-vulkan
