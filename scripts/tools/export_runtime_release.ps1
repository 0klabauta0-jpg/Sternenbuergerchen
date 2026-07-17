param(
	[string]$Preset = "",
	[string]$ContractPath = "",
	[switch]$SkipExport
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

function Get-ConfigQuotedValue {
	param(
		[string]$Content,
		[string]$Key
	)
	$escapedKey = [regex]::Escape($Key)
	$match = [regex]::Match($Content, "(?m)^$escapedKey=`"([^`"]*)`"$")
	if (-not $match.Success) {
		throw "Missing quoted export preset setting: $Key"
	}
	return $match.Groups[1].Value
}

function Assert-ExportPresetMatchesContract {
	param(
		[string]$Content,
		[object]$Contract,
		[string]$PresetName
	)
	$configuredName = Get-ConfigQuotedValue -Content $Content -Key "name"
	if ($configuredName -cne $PresetName) {
		throw "Tracked export preset name '$configuredName' does not match contract '$PresetName'."
	}
	$configuredPath = Get-ConfigQuotedValue -Content $Content -Key "export_path"
	$contractPath = [string]$Contract.runtime_export_path
	if ($configuredPath -cne $contractPath) {
		throw "Tracked export path '$configuredPath' does not match contract '$contractPath'."
	}
	$configuredExcludes = @((Get-ConfigQuotedValue -Content $Content -Key "exclude_filter").Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
	$contractExcludes = @($Contract.exclude_filter_patterns | ForEach-Object { [string]$_ })
	if (($configuredExcludes -join "`n") -cne ($contractExcludes -join "`n")) {
		throw "Tracked exclude_filter does not match data/export_runtime_package_contract.json."
	}
}

function Get-GitValue {
	param(
		[string]$RepoRoot,
		[string[]]$Arguments
	)
	$previousLocation = Get-Location
	try {
		Set-Location $RepoRoot
		return [string](& git @Arguments 2>$null).Trim()
	} finally {
		Set-Location $previousLocation
	}
}

function Test-GitTrackedWorktreeClean {
	param([string]$RepoRoot)
	$previousLocation = Get-Location
	try {
		Set-Location $RepoRoot
		& git diff --quiet
		$unstagedClean = ($LASTEXITCODE -eq 0)
		& git diff --cached --quiet
		$stagedClean = ($LASTEXITCODE -eq 0)
		return $unstagedClean -and $stagedClean
	} finally {
		Set-Location $previousLocation
	}
}

function Write-ReleaseBuildProvenance {
	param(
		[string]$RepoRoot,
		[object]$Contract
	)
	$exePath = [System.IO.Path]::GetFullPath((Join-Path $RepoRoot ([string]$Contract.runtime_export_path)))
	$releaseDirectory = Split-Path -Parent $exePath
	$baseName = [System.IO.Path]::GetFileNameWithoutExtension($exePath)
	$pckPath = Join-Path $releaseDirectory "$baseName.pck"
	if (-not (Test-Path -LiteralPath $exePath -PathType Leaf)) {
		throw "Runtime export completed without EXE: $exePath"
	}
	if (-not (Test-Path -LiteralPath $pckPath -PathType Leaf)) {
		throw "Runtime export completed without PCK: $pckPath"
	}
	$provenanceFileName = [string]$Contract.runtime_provenance_file
	if ([string]::IsNullOrWhiteSpace($provenanceFileName)) {
		$provenanceFileName = "release_build_provenance.json"
	}
	$provenancePath = Join-Path $releaseDirectory $provenanceFileName
	$pckItem = Get-Item -LiteralPath $pckPath
	$provenance = [ordered]@{
		schema = "sternenbuergerchen.release_build_provenance.v1"
		task_id = "TASK_1073"
		exported_at_utc = [DateTime]::UtcNow.ToString("o")
		branch = Get-GitValue -RepoRoot $RepoRoot -Arguments @("branch", "--show-current")
		git_commit = Get-GitValue -RepoRoot $RepoRoot -Arguments @("rev-parse", "HEAD")
		runtime_export_path = [string]$Contract.runtime_export_path
		exe_name = [System.IO.Path]::GetFileName($exePath)
		pck_name = [System.IO.Path]::GetFileName($pckPath)
		pck_size_bytes = [int64]$pckItem.Length
		pck_sha256 = [string](Get-FileHash -LiteralPath $pckPath -Algorithm SHA256).Hash.ToLowerInvariant()
		tracked_worktree_clean = $true
		read_only_consumer_required = $true
	}
	$provenance | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $provenancePath -Encoding UTF8
	Write-Host "Release provenance: $provenancePath"
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

if (-not $SkipExport -and -not (Test-GitTrackedWorktreeClean -RepoRoot $repoRoot)) {
	throw "Refusing runtime export with tracked Git changes. Commit or stash the tracked worktree first."
}

$originalContent = Get-Content -LiteralPath $exportPresetPath -Raw
Assert-ExportPresetMatchesContract -Content $originalContent -Contract $contract -PresetName $Preset
Write-Host "Tracked export preset matches runtime package contract."

if ($SkipExport) {
	Write-Host "SkipExport set; validated tracked export preset only."
	exit 0
}

$runtimeExportPath = [System.IO.Path]::GetFullPath((Join-Path $repoRoot ([string]$contract.runtime_export_path)))
$runtimeExportDirectory = Split-Path -Parent $runtimeExportPath
New-Item -ItemType Directory -Force -Path $runtimeExportDirectory | Out-Null

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
}

Write-ReleaseBuildProvenance -RepoRoot $repoRoot -Contract $contract
