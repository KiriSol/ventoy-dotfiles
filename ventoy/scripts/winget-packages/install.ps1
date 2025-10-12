param (
    [string]$File = "packages.json",
    [switch]$Force = $false
)

function Show-InstallationSummary {
    param($Results)

    $success = ($Results | Where-Object { $_.Success }).Count
    $failed = ($Results | Where-Object { !$_.Success }).Count

    Write-Host "Results:" -ForegroundColor Magenta
    Write-Host "  Success: $success" -ForegroundColor Green
    Write-Host "  Failed: $failed" -ForegroundColor Red

    if ($failed -gt 0) {
        Write-Host "Packages with errors:" -ForegroundColor Red
        $Results | Where-Object { !$_.Success } | ForEach-Object {
            Write-Host "  - $($_.Package) (code: $($_.ExitCode))" -ForegroundColor Red
        }
    }
}

function Install-Packages {
    param (
        [string]$FilePath,
        [bool]$ForceInstall = $false
    )

    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw "winget not found!"
    }
    if (-not (Test-Path $FilePath)) {
        throw "File '$FilePath' not found!"
    }

    $JsonFile = Get-Content $FilePath | ConvertFrom-Json
    $packages = $JsonFile.packages
    $scope = $JsonFile.scope

    if ($scope -ne "user" -and $scope -ne "machine") {
        throw "Invalid scope: '$scope'!"
    }

    Write-Host "Found $($packages.Count) packages" -ForegroundColor Green

    if (-not $ForceInstall) {
        Write-Host "Packages for install (scope: $scope):" -ForegroundColor Yellow
        $packages | ForEach-Object { Write-Host "  - $_" }

        $confirm = Read-Host "`nContuine? (Y/n)"
        if ($confirm -ne 'y' -and $confirm -ne 'Y' -and $confirm -ne '') {
            Write-Host "Canceled by User." -ForegroundColor Yellow
            return
        }
    }

    # Installation
    $results = @()

    foreach ($pack in $packages) {
        Write-Host "Installation: $pack" -ForegroundColor Cyan

        $argsumants = @(
            "install",
            "--id", "$pack", "-e",
            "--silent",
            "--accept-source-agreements",
            "--accept-package-agreements",
            "--scope=$scope"
        )

        $process = Start-Process -FilePath "winget" -ArgumentList $argsumants -Wait -PassThru -NoNewWindow

        $res = [PSCustomObject]@{
            Package  = $pack
            Success  = ($process.ExitCode -eq 0)
            ExitCode = $process.ExitCode
        }

        $results += $res

        if ($res.Success) {
            Write-Host "  - Success" -ForegroundColor Green
        }
        else {
            Write-Host "  - Error (code: $($res.ExitCode))" -ForegroundColor Red
        }
    }

    Show-InstallationSummary -Results $results
}

# Run
try {
    Install-Packages -FilePath $File -ForceInstall $Force
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}
