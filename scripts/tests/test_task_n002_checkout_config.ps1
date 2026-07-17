param(
	[string]$ProjectRoot = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
	$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
} else {
	$ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
}

$script:failures = [System.Collections.Generic.List[string]]::new()

function Assert-Contract {
	param(
		[bool]$Condition,
		[string]$Message
	)
	if ($Condition) {
		Write-Host "PASS: $Message"
		return
	}
	$script:failures.Add($Message)
	Write-Host "FAIL: $Message"
}

function Get-TrackedFiles {
	$lines = @(& git -C $ProjectRoot ls-files -- 2>$null)
	if ($LASTEXITCODE -ne 0) {
		throw "git ls-files failed for $ProjectRoot"
	}
	return [System.Collections.Generic.HashSet[string]]::new(
		[string[]]($lines | ForEach-Object { $_.Replace('\', '/') }),
		[System.StringComparer]::OrdinalIgnoreCase
	)
}

function Get-ActiveIgnorePatterns {
	param([string]$Path)
	return @(
		Get-Content -LiteralPath $Path |
			ForEach-Object { $_.Trim() } |
			Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and -not $_.StartsWith('#') }
	)
}

function Get-RepoRelativePath {
	param([string]$FullPath)
	$rootWithSeparator = $ProjectRoot.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
	$rootUri = [Uri]$rootWithSeparator
	$fileUri = [Uri]$FullPath
	return [Uri]::UnescapeDataString($rootUri.MakeRelativeUri($fileUri).ToString()).Replace('\', '/')
}

$tracked = Get-TrackedFiles
$ignorePath = Join-Path $ProjectRoot ".gitignore"
$ignorePatterns = Get-ActiveIgnorePatterns -Path $ignorePath

Assert-Contract -Condition (-not ($ignorePatterns -contains "*.uid")) -Message "Godot UID-Sidecars werden nicht pauschal ignoriert"
Assert-Contract -Condition (($ignorePatterns -contains ".godot/") -or ($ignorePatterns -contains "/.godot/")) -Message "Der lokale Godot-Importcache .godot bleibt ignoriert"
Assert-Contract -Condition ($ignorePatterns -contains "/builds/") -Message "Repository-lokale Export-Builds werden ignoriert"
Assert-Contract -Condition (($ignorePatterns -contains "export_credentials.cfg") -or ($ignorePatterns -contains "/export_credentials.cfg")) -Message "Export-Credentials bleiben lokal"

$presetRelative = "export_presets.cfg"
$presetPath = Join-Path $ProjectRoot $presetRelative
Assert-Contract -Condition (Test-Path -LiteralPath $presetPath -PathType Leaf) -Message "Ein Windows-Exportpreset ist vorhanden"
Assert-Contract -Condition ($tracked.Contains($presetRelative)) -Message "export_presets.cfg ist versioniert"

if (Test-Path -LiteralPath $presetPath -PathType Leaf) {
	$presetText = Get-Content -LiteralPath $presetPath -Raw
	Assert-Contract -Condition ($presetText -match '(?m)^name="Windows Desktop"$') -Message "Das Preset heißt Windows Desktop"
	Assert-Contract -Condition ($presetText -match '(?m)^platform="Windows Desktop"$') -Message "Das Preset nutzt die Windows-Desktop-Plattform"
	Assert-Contract -Condition ($presetText -match '(?m)^export_path="builds/Sternenbuergerchen_rel\.exe"$') -Message "Der Exportpfad ist repository-relativ und deterministisch"
	Assert-Contract -Condition (-not ($presetText -match '(?im)([A-Z]:\\|/Users/|/home/|credential|password|private[_ -]?key|ssh|remote[_ -]?deploy)')) -Message "Das Preset enthält keine persönlichen Pfade, Credentials oder Remote-Deploy-Befehle"
}

$expectedAutoloads = [ordered]@{
	"addons/netfox/network-time.gd.uid" = "uid://cnqdxyjptkfvp"
	"addons/netfox/network-time-synchronizer.gd.uid" = "uid://5rmn2ik3kjo8"
	"addons/netfox/rollback/network-rollback.gd.uid" = "uid://gas743comroj"
	"addons/netfox/network-events.gd.uid" = "uid://bdmobxxptryj0"
	"addons/netfox/network-performance.gd.uid" = "uid://cqgf7aqmjfoa3"
	"addons/netfox/servers/rollback-simulation-server.gd.uid" = "uid://d5vx6blln3jr"
	"addons/netfox/servers/network-history-server.gd.uid" = "uid://c554fbsy6yos3"
	"addons/netfox/servers/network-synchronization-server.gd.uid" = "uid://yrhqsbd5ubhs"
	"addons/netfox/servers/network-identity-server.gd.uid" = "uid://pc8gwg1lbusp"
	"addons/netfox/servers/network-command-server.gd.uid" = "uid://mkgjb8gdl0fp"
	"addons/netfox/servers/rollback-liveness-server.gd.uid" = "uid://beo1554xbapmy"
}

foreach ($entry in $expectedAutoloads.GetEnumerator()) {
	$uidRelative = [string]$entry.Key
	$uidPath = Join-Path $ProjectRoot $uidRelative
	$sourceRelative = $uidRelative.Substring(0, $uidRelative.Length - 4)
	Assert-Contract -Condition ($tracked.Contains($sourceRelative)) -Message "Autoload-Quelle ist versioniert: $sourceRelative"
	Assert-Contract -Condition ($tracked.Contains($uidRelative)) -Message "Autoload-UID ist versioniert: $uidRelative"
	if (Test-Path -LiteralPath $uidPath -PathType Leaf) {
		$actualUid = (Get-Content -LiteralPath $uidPath -Raw).Trim()
		Assert-Contract -Condition ($actualUid -ceq [string]$entry.Value) -Message "Autoload-UID bleibt stabil: $uidRelative"
	} else {
		Assert-Contract -Condition $false -Message "Autoload-UID ist vorhanden: $uidRelative"
	}
}

$uidFiles = @(Get-ChildItem -LiteralPath $ProjectRoot -Recurse -File -Filter "*.uid" | Where-Object {
	$relative = Get-RepoRelativePath -FullPath $_.FullName
	-not $relative.StartsWith('.git/') -and -not $relative.StartsWith('.godot/') -and -not $relative.StartsWith('builds/')
})
foreach ($uidFile in $uidFiles) {
	$uidRelative = Get-RepoRelativePath -FullPath $uidFile.FullName
	$sourceRelative = $uidRelative.Substring(0, $uidRelative.Length - 4)
	Assert-Contract -Condition ($tracked.Contains($sourceRelative)) -Message "UID-Sidecar besitzt eine versionierte Quelle: $uidRelative"
}

$contractPath = Join-Path $ProjectRoot "data\export_runtime_package_contract.json"
$contract = Get-Content -LiteralPath $contractPath -Raw | ConvertFrom-Json
Assert-Contract -Condition ([string]$contract.runtime_export_path -ceq "builds/Sternenbuergerchen_rel.exe") -Message "Exportvertrag nutzt denselben relativen Buildpfad"
Assert-Contract -Condition ([bool]$contract.export_preset_tracked) -Message "Exportvertrag markiert das Preset als versioniert"
Assert-Contract -Condition (-not [bool]$contract.restore_local_export_preset_after_run) -Message "Workflow restauriert keinen angeblich lokalen Preset mehr"

$exportWorkflowPath = Join-Path $ProjectRoot "scripts\tools\export_runtime_release.ps1"
$exportWorkflow = Get-Content -LiteralPath $exportWorkflowPath -Raw
Assert-Contract -Condition (-not ($exportWorkflow -match 'runtime_backup|KeepPatchedPreset|Set-OrReplaceLine')) -Message "Exportworkflow mutiert oder restauriert den versionierten Preset nicht"
Assert-Contract -Condition ($exportWorkflow -match 'Assert-ExportPresetMatchesContract') -Message "Exportworkflow validiert Preset und Vertrag vor dem Export"

$freshVerifierRelative = "scripts/tests/verify_task_n002_fresh_checkout.ps1"
$freshVerifierPath = Join-Path $ProjectRoot $freshVerifierRelative
Assert-Contract -Condition (Test-Path -LiteralPath $freshVerifierPath -PathType Leaf) -Message "Fresh-Checkout-Verifier ist vorhanden"
Assert-Contract -Condition ($tracked.Contains($freshVerifierRelative)) -Message "Fresh-Checkout-Verifier ist versioniert"
if (Test-Path -LiteralPath $freshVerifierPath -PathType Leaf) {
	$freshVerifier = Get-Content -LiteralPath $freshVerifierPath -Raw
	Assert-Contract -Condition ($freshVerifier -match '(?s)clone.*--no-local.*--no-hardlinks') -Message "Verifier nutzt einen echten externen Git-Clone"
	Assert-Contract -Condition ($freshVerifier -match 'test_task_n002_checkout_config\.ps1') -Message "Verifier führt den statischen Vertrag im Clone aus"
	Assert-Contract -Condition ($freshVerifier -match '--headless' -and $freshVerifier -match '--editor' -and $freshVerifier -match '--quit') -Message "Verifier importiert den Clone headless"
	Assert-Contract -Condition ($freshVerifier -match '--quit-after') -Message "Verifier startet den Clone mit endlichem Zeitbudget"
	Assert-Contract -Condition ($freshVerifier -match 'UID|Autoload|Parse Error|SCRIPT ERROR') -Message "Verifier behandelt Setup-Fehlermuster als hartes Gate"
	Assert-Contract -Condition ($freshVerifier -match 'KEEP' -or $freshVerifier -match 'behalten') -Message "Verifier behält Temp und Logs bei Fehlern"
}

if ($script:failures.Count -gt 0) {
	Write-Host "TASK_N002_CHECKOUT_CONFIG: FAILED ($($script:failures.Count))"
	exit 1
}

Write-Host "TASK_N002_CHECKOUT_CONFIG: PASSED"
exit 0
