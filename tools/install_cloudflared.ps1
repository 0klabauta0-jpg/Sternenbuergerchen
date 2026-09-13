param([string]$Destination = (Join-Path $env:LOCALAPPDATA 'SternenBuergerchen-Neustart/tools/cloudflared.exe'))
$ErrorActionPreference = 'Stop'
# Portable official binary only: no MSI, Windows service, PATH or router changes.
$version = '2026.9.1'
$sha256 = '2837888cc0f5d58f15b6dc478376de90b4d3ba5241c7947455d1e0a0df429712'
$url = "https://github.com/cloudflare/cloudflared/releases/download/$version/cloudflared-windows-amd64.exe"
$destinationFull = [IO.Path]::GetFullPath($Destination)
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destinationFull) | Out-Null
if ((Test-Path -LiteralPath $destinationFull) -and (Get-FileHash -LiteralPath $destinationFull -Algorithm SHA256).Hash.ToLowerInvariant() -eq $sha256) {
    Write-Output "Internet-Helfer bereits bereit: $destinationFull"
    exit 0
}
$downloadPath = $destinationFull + '.' + [guid]::NewGuid().ToString('N') + '.download'
Invoke-WebRequest -Uri $url -OutFile $downloadPath
if ((Get-FileHash -LiteralPath $downloadPath -Algorithm SHA256).Hash.ToLowerInvariant() -ne $sha256) {
    throw 'Pruefsumme des offiziellen Downloads stimmt nicht; Datei wird nicht ausgefuehrt.'
}
Move-Item -LiteralPath $downloadPath -Destination $destinationFull -Force
& $destinationFull --version
if ($LASTEXITCODE -ne 0) { throw 'Internet-Helfer startet nicht.' }
Write-Output "Internet-Helfer bereit: $destinationFull"
