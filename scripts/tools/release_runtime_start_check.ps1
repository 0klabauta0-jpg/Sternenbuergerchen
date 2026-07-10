param(
	[string]$ContractPath = "",
	[int]$MaxAgeHours = 48,
	[switch]$RequireNoRunningProcess,
	[switch]$JsonOnly
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

function Resolve-FullPathFromRoot {
	param(
		[string]$Root,
		[string]$PathValue
	)
	if ([System.IO.Path]::IsPathRooted($PathValue)) {
		return [System.IO.Path]::GetFullPath($PathValue)
	}
	return [System.IO.Path]::GetFullPath((Join-Path $Root $PathValue))
}

function Get-FileSnapshot {
	param([string]$Path)
	$exists = Test-Path -LiteralPath $Path -PathType Leaf
	$snapshot = [ordered]@{
		path = $Path
		exists = $exists
		size_bytes = 0
		last_write_time = $null
		age_hours = $null
	}
	if ($exists) {
		$item = Get-Item -LiteralPath $Path
		$snapshot.size_bytes = [int64]$item.Length
		$snapshot.last_write_time = $item.LastWriteTime.ToString("o")
		$snapshot.age_hours = [math]::Round(((Get-Date) - $item.LastWriteTime).TotalHours, 2)
	}
	return $snapshot
}

function Get-ReleaseProvenanceSnapshot {
	param([string]$Path)
	$snapshot = [ordered]@{
		path = $Path
		exists = Test-Path -LiteralPath $Path -PathType Leaf
		valid = $false
		git_commit = ""
		pck_sha256 = ""
		pck_size_bytes = 0
		exported_at_utc = ""
		tracked_worktree_clean = $false
	}
	if (-not $snapshot.exists) {
		return $snapshot
	}
	try {
		$data = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
		$snapshot.valid = ([string]$data.schema -eq "sternenbuergerchen.release_build_provenance.v1") -and -not [string]::IsNullOrWhiteSpace([string]$data.git_commit) -and -not [string]::IsNullOrWhiteSpace([string]$data.pck_sha256) -and [bool]$data.tracked_worktree_clean
		$snapshot.git_commit = [string]$data.git_commit
		$snapshot.pck_sha256 = [string]$data.pck_sha256
		$snapshot.pck_size_bytes = [int64]$data.pck_size_bytes
		$snapshot.exported_at_utc = [string]$data.exported_at_utc
		$snapshot.tracked_worktree_clean = [bool]$data.tracked_worktree_clean
	} catch {
		$snapshot.valid = $false
	}
	return $snapshot
}

function Get-ReleaseProcesses {
	param(
		[string]$ExePath,
		[string]$ConsoleExePath
	)
	$targets = @(
		[System.IO.Path]::GetFullPath($ExePath).ToLowerInvariant(),
		[System.IO.Path]::GetFullPath($ConsoleExePath).ToLowerInvariant()
	)
	$matches = @()
	$processes = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue
	foreach ($process in $processes) {
		if ([string]::IsNullOrWhiteSpace($process.ExecutablePath)) {
			continue
		}
		$processPath = [System.IO.Path]::GetFullPath([string]$process.ExecutablePath).ToLowerInvariant()
		if ($targets -contains $processPath) {
			$matches += [ordered]@{
				process_id = [int]$process.ProcessId
				name = [string]$process.Name
				executable_path = [string]$process.ExecutablePath
			}
		}
	}
	return @($matches)
}

function Get-GitValue {
	param([string[]]$Arguments)
	try {
		$previousLocation = Get-Location
		Set-Location $script:repoRoot
		$value = (& git @Arguments 2>$null)
		Set-Location $previousLocation
		return [string]$value
	} catch {
		try { Set-Location $previousLocation } catch {}
		return ""
	}
}

$script:repoRoot = Resolve-RepoRoot
if ([string]::IsNullOrWhiteSpace($ContractPath)) {
	$ContractPath = Join-Path $script:repoRoot "data\export_runtime_package_contract.json"
}

$contract = Read-JsonFile -Path $ContractPath
$exePath = Resolve-FullPathFromRoot -Root $script:repoRoot -PathValue ([string]$contract.runtime_export_path)
$releaseDirectory = Split-Path -Parent $exePath
$baseName = [System.IO.Path]::GetFileNameWithoutExtension($exePath)
$pckPath = Join-Path $releaseDirectory "$baseName.pck"
$consoleExePath = Join-Path $releaseDirectory "$baseName.console.exe"
$runtimeDllNames = @(
	"liblimboai.windows.template_release.x86_64.dll",
	"libterrain.windows.release.x86_64.dll"
)
$provenanceFileName = [string]$contract.runtime_provenance_file
if ([string]::IsNullOrWhiteSpace($provenanceFileName)) {
	$provenanceFileName = "release_build_provenance.json"
}
$provenancePath = Join-Path $releaseDirectory $provenanceFileName

$requiredFiles = [ordered]@{
	exe = Get-FileSnapshot -Path $exePath
	console_exe = Get-FileSnapshot -Path $consoleExePath
	pck = Get-FileSnapshot -Path $pckPath
}
foreach ($dllName in $runtimeDllNames) {
	$requiredFiles[$dllName] = Get-FileSnapshot -Path (Join-Path $releaseDirectory $dllName)
}

$hardFailures = @()
$warnings = @()
foreach ($entry in $requiredFiles.GetEnumerator()) {
	if (-not $entry.Value.exists) {
		$hardFailures += "missing_required_file:$($entry.Key)"
	}
}

$provenance = Get-ReleaseProvenanceSnapshot -Path $provenancePath
$expectedGitCommit = Get-GitValue -Arguments @("rev-parse", "HEAD")
$actualPckSha256 = ""
if (-not $provenance.exists) {
	$hardFailures += "missing_release_provenance"
} elseif (-not $provenance.valid) {
	$hardFailures += "invalid_release_provenance"
} elseif ([string]::IsNullOrWhiteSpace($expectedGitCommit)) {
	$hardFailures += "repository_git_head_unavailable"
} else {
	if ($provenance.git_commit -ne $expectedGitCommit) {
		$hardFailures += "release_provenance_git_commit_mismatch"
	}
	if ($requiredFiles.pck.exists) {
		$actualPckSha256 = [string](Get-FileHash -LiteralPath $pckPath -Algorithm SHA256).Hash.ToLowerInvariant()
		if ($provenance.pck_size_bytes -ne [int64]$requiredFiles.pck.size_bytes -or $provenance.pck_sha256.ToLowerInvariant() -ne $actualPckSha256) {
			$hardFailures += "release_provenance_pck_mismatch"
		}
	}
}

$pckFreshEnough = $false
if ($requiredFiles.pck.exists -and $requiredFiles.pck.age_hours -ne $null) {
	$pckFreshEnough = ([double]$requiredFiles.pck.age_hours -le [double]$MaxAgeHours)
	if (-not $pckFreshEnough) {
		$warnings += "pck_older_than_${MaxAgeHours}h"
	}
}

$runningProcesses = Get-ReleaseProcesses -ExePath $exePath -ConsoleExePath $consoleExePath
if ($runningProcesses.Count -gt 0) {
	$warnings += "release_process_already_running"
	if ($RequireNoRunningProcess) {
		$hardFailures += "release_process_already_running"
	}
}

$tempFiles = @()
if (Test-Path -LiteralPath $releaseDirectory -PathType Container) {
	$tempFiles = @(Get-ChildItem -LiteralPath $releaseDirectory -Filter "*~RF*.TMP" -File -ErrorAction SilentlyContinue | ForEach-Object {
		[ordered]@{
			path = $_.FullName
			size_bytes = [int64]$_.Length
			last_write_time = $_.LastWriteTime.ToString("o")
			age_hours = [math]::Round(((Get-Date) - $_.LastWriteTime).TotalHours, 2)
		}
	})
}
if ($tempFiles.Count -gt 0) {
	$warnings += "release_temp_files_present"
}

$gate = "pass"
if ($hardFailures.Count -gt 0) {
	$gate = "fail"
} elseif ($warnings.Count -gt 0) {
	$gate = "review"
}

$manifest = [ordered]@{
	schema = "sternenbuergerchen.release_runtime_start_check.v1"
	task_id = "TASK_818"
	gate = $gate
	repo_root = $script:repoRoot
	branch = Get-GitValue -Arguments @("branch", "--show-current")
	git_head = Get-GitValue -Arguments @("rev-parse", "--short", "HEAD")
	expected_git_commit = $expectedGitCommit
	contract_path = [System.IO.Path]::GetFullPath($ContractPath)
	release_directory = $releaseDirectory
	exe_path = $exePath
	pck_path = $pckPath
	console_exe_path = $consoleExePath
	max_age_hours = $MaxAgeHours
	pck_fresh_enough = $pckFreshEnough
	release_provenance = $provenance
	release_provenance_path = $provenancePath
	actual_pck_sha256 = $actualPckSha256
	required_files = $requiredFiles
	running_processes = @($runningProcesses)
	temp_files = @($tempFiles)
	warnings = @($warnings)
	hard_failures = @($hardFailures)
	start_command = "Start-Process -FilePath `"$exePath`" -WorkingDirectory `"$releaseDirectory`""
	read_only = $true
	kills_processes = $false
	starts_processes = $false
	updates_shortcuts = $false
}

$tmpDirectory = Join-Path $script:repoRoot "tmp"
if (-not (Test-Path -LiteralPath $tmpDirectory -PathType Container)) {
	New-Item -ItemType Directory -Path $tmpDirectory | Out-Null
}
$manifestPath = Join-Path $tmpDirectory "release_runtime_start_check.json"
$manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifestPath -Encoding UTF8

if ($JsonOnly) {
	$manifest | ConvertTo-Json -Depth 8
} else {
	Write-Host "Release runtime start check: $gate"
	Write-Host "EXE: $exePath"
	Write-Host "PCK: $pckPath"
	Write-Host "Manifest: $manifestPath"
	if ($warnings.Count -gt 0) {
		Write-Host "Warnings: $($warnings -join ', ')"
	}
	if ($hardFailures.Count -gt 0) {
		Write-Host "Hard failures: $($hardFailures -join ', ')"
	}
	if ($runningProcesses.Count -gt 0) {
		Write-Host "Running release process ids: $((@($runningProcesses) | ForEach-Object { $_.process_id }) -join ', ')"
	}
	if ($tempFiles.Count -gt 0) {
		Write-Host "Temp files: $($tempFiles.Count)"
	}
	Write-Host "Start command: $($manifest.start_command)"
}

if ($hardFailures.Count -gt 0) {
	exit 2
}
exit 0
