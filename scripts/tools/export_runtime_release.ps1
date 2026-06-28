param(
	[string]$Preset = "",
	[string]$ContractPath = "",
	[switch]$SkipExport,
	[switch]$KeepPatchedPreset
)

$ErrorActionPreference = "Stop"

function Resolve-RepoRoot {
	$scriptDirectory = Split-Path -Parent $PSCommandPath
	return (Resolve-Path (Join-Path $scriptDirectory "..\..")).Path
}

function Read-JsonFile {
	param([string]$Path)
	if (-not (Test-Path -LiteralPath $Path)) {
		throw "Missing JSON file: $Path"
	}
	return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Set-OrReplaceLine {
	param(
		[string]$Content,
		[string]$Key,
		[string]$Value
	)
	$escapedKey = [regex]::Escape($Key)
	$line = "$Key=`"$Value`""
	if ($Content -match "(?m)^$escapedKey=") {
		return [regex]::Replace($Content, "(?m)^$escapedKey=.*$", $line)
	}
	return $Content.TrimEnd() + [Environment]::NewLine + $line + [Environment]::NewLine
}

$repoRoot = Resolve-RepoRoot
if ([string]::IsNullOrWhiteSpace($ContractPath)) {
	$ContractPath = Join-Path $repoRoot "data\export_runtime_package_contract.json"
}
$contract = Read-JsonFile -Path $ContractPath

if ([string]::IsNullOrWhiteSpace($Preset)) {
	$Preset = [string]$contract.preset_name
}
if ([string]::IsNullOrWhiteSpace($Preset)) {
	throw "No export preset name configured."
}

$exportPresetPath = Join-Path $repoRoot ([string]$contract.export_preset_path)
if (-not (Test-Path -LiteralPath $exportPresetPath)) {
	throw "Missing local export preset: $exportPresetPath"
}

$excludePatterns = @($contract.exclude_filter_patterns | ForEach-Object { [string]$_ })
if ($excludePatterns.Count -eq 0) {
	throw "Export runtime package contract contains no exclude_filter_patterns."
}
$excludeFilter = ($excludePatterns -join ",")

$originalContent = Get-Content -LiteralPath $exportPresetPath -Raw
$patchedContent = Set-OrReplaceLine -Content $originalContent -Key "exclude_filter" -Value $excludeFilter
$patchedContent = Set-OrReplaceLine -Content $patchedContent -Key "export_path" -Value ([string]$contract.runtime_export_path)

if ($patchedContent -eq $originalContent) {
	Write-Host "Export preset already matches runtime package contract."
} else {
	$backupPath = "$exportPresetPath.runtime_backup"
	[System.IO.File]::WriteAllText($backupPath, $originalContent, [System.Text.UTF8Encoding]::new($false))
	[System.IO.File]::WriteAllText($exportPresetPath, $patchedContent, [System.Text.UTF8Encoding]::new($false))
	Write-Host "Patched local export preset for runtime export."
}

if ($SkipExport) {
	Write-Host "SkipExport set; validated and patched export preset only."
	if (-not $KeepPatchedPreset -and (Test-Path -LiteralPath "$exportPresetPath.runtime_backup")) {
		Move-Item -LiteralPath "$exportPresetPath.runtime_backup" -Destination $exportPresetPath -Force
		Write-Host "Restored local export preset after SkipExport."
	}
	exit 0
}

$pushedLocation = $false
try {
	Push-Location $repoRoot
	$pushedLocation = $true
	$stdoutPath = [System.IO.Path]::GetTempFileName()
	$stderrPath = [System.IO.Path]::GetTempFileName()
	try {
		$escapedPreset = $Preset.Replace('"', '\"')
		$godotArguments = "--headless --path . --export-release `"$escapedPreset`""
		$process = Start-Process -FilePath "godot_console.exe" -ArgumentList $godotArguments -NoNewWindow -Wait -PassThru -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
		if (Test-Path -LiteralPath $stdoutPath) {
			Get-Content -LiteralPath $stdoutPath | ForEach-Object { Write-Output $_ }
		}
		if (Test-Path -LiteralPath $stderrPath) {
			Get-Content -LiteralPath $stderrPath | ForEach-Object { Write-Output $_ }
		}
		$exitCode = $process.ExitCode
	} finally {
		Remove-Item -LiteralPath $stdoutPath -Force -ErrorAction SilentlyContinue
		Remove-Item -LiteralPath $stderrPath -Force -ErrorAction SilentlyContinue
	}
	Pop-Location
	$pushedLocation = $false
	if ($exitCode -ne 0) {
		throw "Godot export failed with exit code $exitCode"
	}
} finally {
	if ($pushedLocation) {
		try { Pop-Location } catch {}
	}
	if (-not $KeepPatchedPreset -and (Test-Path -LiteralPath "$exportPresetPath.runtime_backup")) {
		Move-Item -LiteralPath "$exportPresetPath.runtime_backup" -Destination $exportPresetPath -Force
		Write-Host "Restored local export preset."
	}
}
