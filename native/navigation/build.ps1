param(
    [string]$DependencyRoot = "$env:LOCALAPPDATA/SternenBuergerchen/native-navigation-build",
    [int]$Jobs = 8
)
$ErrorActionPreference = 'Stop'
$bindingCommit = 'e83fd0904c13356ed1d4c3d09f8bb9132bdc6b77'
New-Item -ItemType Directory -Force $DependencyRoot | Out-Null
$cpp = Join-Path $DependencyRoot 'godot-cpp'
$python = Join-Path $DependencyRoot 'venv/Scripts/python.exe'
if (!(Test-Path -LiteralPath $cpp)) {
    git clone --depth 1 --branch godot-4.5-stable https://github.com/godotengine/godot-cpp.git $cpp
    if ($LASTEXITCODE -ne 0) { throw 'godot-cpp clone failed' }
}
$actualCommit = git -C $cpp rev-parse HEAD
if ($actualCommit -ne $bindingCommit) { throw "Unexpected binding commit: $actualCommit" }
if (!(Test-Path -LiteralPath $python)) {
    python -m venv (Join-Path $DependencyRoot 'venv')
    if ($LASTEXITCODE -ne 0) { throw 'venv creation failed' }
}
& $python -m pip install scons==4.11.1
if ($LASTEXITCODE -ne 0) { throw 'SCons setup failed' }
$oldCpp = $env:GODOT_CPP_DIR
try {
    $env:GODOT_CPP_DIR = $cpp
    Push-Location $PSScriptRoot
    & $python -m SCons platform=windows target=template_release arch=x86_64 precision=single optimize=speed "-j$Jobs"
    if ($LASTEXITCODE -ne 0) { throw 'Native navigation build failed' }
} finally {
    Pop-Location
    $env:GODOT_CPP_DIR = $oldCpp
}
