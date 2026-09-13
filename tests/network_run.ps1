param([int]$Port = 27991, [switch]$Visual)
# N4 uses the same real command path for LAN and authenticated public WSS.
& (Join-Path $PSScriptRoot 'internet_run.ps1') -Lan -Visual:$Visual -Port $Port
