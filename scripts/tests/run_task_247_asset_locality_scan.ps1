$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSCommandPath))
Set-Location $repoRoot
$repoRootFull = (Resolve-Path -LiteralPath $repoRoot).Path.TrimEnd("\", "/")

$textExtensions = @(
    ".cfg",
    ".gd",
    ".godot",
    ".import",
    ".json",
    ".md",
    ".toml",
    ".tres",
    ".tscn",
    ".txt"
)

$scanRoots = @(
    "scenes",
    "scripts",
    "data",
    "Assets",
    "maps",
    "docs",
    "project.godot"
)

$markers = @(
    "C:\Users\",
    "C:/Users/",
    "%USERPROFILE%",
    "file://",
    "Pictures\Sternen",
    "Pictures/Sternen"
)

function Get-PathKind {
    param([string]$RelativePath)

    $normalized = $RelativePath -replace "\\", "/"
    if ($normalized -eq "project.godot") {
        return "runtime"
    }
    if ($normalized.StartsWith("scripts/tests/")) {
        return "test-harness"
    }
    if ($normalized.StartsWith("docs/")) {
        return "documentation"
    }
    if ($normalized.StartsWith("Assets/") -and ($normalized.EndsWith(".md") -or $normalized.EndsWith(".txt"))) {
        return "documentation"
    }
    if ($normalized.StartsWith("scenes/") -or $normalized.StartsWith("scripts/") -or $normalized.StartsWith("data/") -or $normalized.StartsWith("maps/")) {
        return "runtime"
    }
    if ($normalized.StartsWith("Assets/") -and $normalized.EndsWith(".import")) {
        return "import-metadata"
    }
    return "other"
}

function Is-GuardLiteral {
    param(
        [string]$RelativePath,
        [string]$Line
    )

    $normalized = $RelativePath -replace "\\", "/"
    if (-not $normalized.StartsWith("scripts/")) {
        return $false
    }
    if ($normalized.StartsWith("scripts/tests/")) {
        return $true
    }
    return $Line.Contains("contains(") -or
        $Line.Contains("begins_with(") -or
        $Line.Contains("forbidden_patterns") -or
        $Line.Contains("_contains_local_path") -or
        $Line.Contains("_string_has_local_path_marker")
}

$files = New-Object System.Collections.Generic.List[string]
foreach ($root in $scanRoots) {
    if (Test-Path -LiteralPath $root -PathType Leaf) {
        $files.Add((Resolve-Path -LiteralPath $root).Path)
        continue
    }
    if (-not (Test-Path -LiteralPath $root -PathType Container)) {
        continue
    }
    Get-ChildItem -LiteralPath $root -Recurse -File -Force |
        Where-Object { $textExtensions -contains $_.Extension.ToLowerInvariant() } |
        ForEach-Object { $files.Add($_.FullName) }
}

$runtimeOffenders = New-Object System.Collections.Generic.List[string]
$guardLiterals = New-Object System.Collections.Generic.List[string]
$docNotes = New-Object System.Collections.Generic.List[string]
$importNotes = New-Object System.Collections.Generic.List[string]
$testHarnessNotes = New-Object System.Collections.Generic.List[string]

foreach ($file in $files) {
    $fullPath = (Resolve-Path -LiteralPath $file).Path
    if ($fullPath.StartsWith($repoRootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        $relative = $fullPath.Substring($repoRootFull.Length).TrimStart("\", "/")
    } else {
        $relative = $fullPath
    }
    $kind = Get-PathKind -RelativePath $relative
    $lineNumber = 0
    foreach ($line in [System.IO.File]::ReadLines($file)) {
        $lineNumber += 1
        $matchesMarker = $false
        foreach ($marker in $markers) {
            if ($line.Contains($marker)) {
                $matchesMarker = $true
                break
            }
        }
        if (-not $matchesMarker) {
            continue
        }
        $entry = "{0}:{1}: {2}" -f $relative, $lineNumber, $line.Trim()
        if (Is-GuardLiteral -RelativePath $relative -Line $line) {
            $guardLiterals.Add($entry)
        } elseif ($kind -eq "runtime") {
            $runtimeOffenders.Add($entry)
        } elseif ($kind -eq "documentation") {
            $docNotes.Add($entry)
        } elseif ($kind -eq "import-metadata") {
            $importNotes.Add($entry)
        } elseif ($kind -eq "test-harness") {
            $testHarnessNotes.Add($entry)
        }
    }
}

Write-Host "TASK_247 asset locality scan"
Write-Host ("Text files scanned: {0}" -f $files.Count)
Write-Host ("Runtime local path violations: {0}" -f $runtimeOffenders.Count)
Write-Host ("Guard literals: {0}" -f $guardLiterals.Count)
Write-Host ("Documentation/source notes: {0}" -f $docNotes.Count)
Write-Host ("Import metadata notes: {0}" -f $importNotes.Count)
Write-Host ("Test-harness notes: {0}" -f $testHarnessNotes.Count)

if ($runtimeOffenders.Count -gt 0) {
    Write-Host "Runtime offenders:"
    $runtimeOffenders | ForEach-Object { Write-Host "  $_" }
    exit 1
}

Write-Host "OK: no runtime local user/source paths found."
exit 0
