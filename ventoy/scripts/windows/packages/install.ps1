param (
    [string]$ScoopListsPath = "lists\scoop",
    [string]$WingetListsPath = "lists\winget"
)

$ErrorActionPreference = "Stop"


## Check requirements

$IsRunAsAdmin = [bool](
    [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not (Get-Command -Name scoop -ErrorAction Ignore)) {
    Write-Host 'Please, install Scoop by himself'
    exit 1
}
if (-not (Get-Command -Name winget -ErrorAction Ignore)) {
    Write-Host 'Winget not found'
    exit 1
}


## Functions

function Scoop-Installation ($File) {
    $data = Get-Content $File -Raw | ConvertFrom-Json
    if ($data.bucket -ne "main") {
        if (-not (Get-Command -Name git -ErrorAction Ignore)) {
            $args = @("install", "main/mingit", "--no-update-scoop")
            if ($data.level -eq "global") {
                if (-not $IsRunAsAdmin) {
                    Write-Host "Please, run as Administrator to global installation"
                    exit 1
                }
                $args += "--global"
            }
            scoop $args
        }
        scoop bucket add $data.bucket
    }
    foreach ($app in $data.apps) {
        $args = @("install", "$($data.bucket)/$app", "--no-update-scoop")
        if ($data.level -eq "global") {
            if (-not $IsRunAsAdmin) {
                Write-Host "Please, run as Administrator to global installation"
                exit 1
            }
            $args += "--global"
        }
        scoop $args
    }
}

function Winget-Installation ($File) {
    $data = Get-Content $File -Raw | ConvertFrom-Json
    foreach ($pkg in $data.packages) {
        $args = @(
            "install", "--id", $pkg.id,
            "--exact", "--silent", "--no-upgrade",
            "--accept-source-agreements", "--accept-package-agreements"
        )
        if ($data.scope -eq "machine") {
            if (-not $IsRunAsAdmin) {
                Write-Host "Please, run as Administrator to machine installation"
                exit 1
            }
            $args += "--scope", "machine"
        }
        if ($pkg.override) { $args += "--override", $pkg.override }
        winget $args
    }
}


## Run

$ScoopLists = Get-ChildItem -Path $ScoopListsPath -Filter "*.json" | Where-Object { $_.Name -notlike ".*" }
$WingetLists = Get-ChildItem -Path $WingetListsPath -Filter "*.json" | Where-Object { $_.Name -notlike ".*" }

foreach ($file in $ScoopLists) {
    Scoop-Installation $file
}

foreach ($file in $WingetLists) {
    Winget-Installation $file
}
