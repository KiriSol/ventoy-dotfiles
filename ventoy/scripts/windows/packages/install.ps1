param (
    [string]$ScoopListsPath = "lists\scoop",
    [string]$WingetListsPath = "lists\winget"
)

$ErrorActionPreference = "Stop"
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

function Test-Cmd ($Name) { return [bool](Get-Command $Name -ErrorAction Ignore) }

if (-not (Test-Cmd scoop))  { throw "Scoop not found" }
if (-not (Test-Cmd winget)) { throw "Winget not found" }

function Process-Lists ($Path, [scriptblock]$Action) {
    if (-not (Test-Path $Path)) { return }
    Get-ChildItem -Path $Path -Filter "*.json" | Where-Object { $_.Name -notlike ".*" } | ForEach-Object {
        try {
            $data = Get-Content $_.FullName -Raw | ConvertFrom-Json
            &$Action $data
        } catch {
            Write-Warning "Failed to process $($_.Name): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

$ScoopAction = {
    param($data)
    $global = $data.level -eq "global"
    if ($global -and -not $IsAdmin) { throw "Admin rights required for global Scoop install" }

    if ($data.bucket -and $data.bucket -ne "main") {
        scoop bucket add $data.bucket 2>$null
    }

    foreach ($app in $data.apps) {
        $id = if ($data.bucket) { "$($data.bucket)/$app" } else { $app }
        $args = @("install", $id, "--no-update-scoop")
        if ($global) { $args += "--global" }
        Write-Host "Scoop: Installing $id" -ForegroundColor Blue
        scoop $args
    }
}

$WingetAction = {
    param($data)
    $machine = $data.scope -eq "machine"
    if ($machine -and -not $IsAdmin) { throw "Admin rights required for machine Winget install" }

    foreach ($pkg in $data.packages) {
        $args = @("install", "--id", $pkg.id, "--exact", "--silent", "--accept-source-agreements", "--accept-package-agreements")
        if ($machine) { $args += "--scope", "machine" }
        if ($pkg.override) { $args += "--override", $pkg.override }
        Write-Host "Winget: Installing $($pkg.id)" -ForegroundColor Blue
        winget $args
    }
}

Process-Lists -Path $ScoopListsPath -Action $ScoopAction
Process-Lists -Path $WingetListsPath -Action $WingetAction

