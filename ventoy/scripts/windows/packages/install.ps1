#Requires -Version 5

param (
    [string]$ScoopListsPath
    [string]$WingetListsPath
    [switch]$Local = $false
)

$ErrorActionPreference = "Stop"
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

Get-Command -Name scoop 1>$null
Get-Command -Name winget 1>$null

Test-Path -Path $ScoopListsPath 1>$null
Test-Path -Path $WingetListsPath 1>$null

function Process-Lists ($Path, [scriptblock]$Action) {
    Get-ChildItem -Path $Path -Filter "*.json" | Where-Object { $_.Name -notlike ".*" } | ForEach-Object {
        $data = Get-Content $_.FullName -Raw | ConvertFrom-Json
        & $Action $data
    }
}

$ScoopAction = {
    param($data)
    $global = if ($Local) { $false } else { $data.level -eq "global" }
    if ($global -and -not $IsAdmin) { throw "Admin rights required for global Scoop install" }

    if ($data.bucket -and $data.bucket -ne "main") {
        & scoop bucket add $data.bucket 1>$null
    }

    foreach ($app in $data.apps) {
        $id = if ($data.bucket) { "$($data.bucket)/$app" } else { $app }
        $args = @("install", $id)
        if ($global) { $args += "--global" }
        & scoop @args
    }
}

$WingetAction = {
    param($data)
    $machine = if ($Local) { $false } else { $data.scope -eq "machine" }
    if ($machine -and -not $IsAdmin) { throw "Admin rights required for machine Winget install" }

    foreach ($pkg in $data.packages) {
        $args = @("install", "--id", $pkg.id, "--exact", "--silent", "--accept-source-agreements", "--accept-package-agreements")
        if ($machine) { $args += "--scope", "machine" }
        if ($pkg.override) { $args += "--override", $pkg.override }
        & winget @args
    }
}

Process-Lists -Path $ScoopListsPath -Action $ScoopAction
Process-Lists -Path $WingetListsPath -Action $WingetAction
