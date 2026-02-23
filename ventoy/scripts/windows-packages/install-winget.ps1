param (
    [Parameter(HelpMessage="Path to json file")]
    [ValidateScript({ Test-Path $_ })]
    [string]$File = "packages.json",

    [switch]$Force = $false
)

function Install-Packages {
    if (-not (Get-Command winget -ErrorAction Ignore)) { throw "winget not found!" }

    $data = Get-Content $File -Raw | ConvertFrom-Json
    $packages = $data.packages
    $scope = $data.scope

    Write-Host "--- The wrapper for Winget ---" -ForegroundColor Cyan
    Write-Host "Found packages: $($packages.Count) (Scope: $scope)"

    # Asking
    if (-not $Force) {
        $packages | ForEach-Object { Write-Host "  [ ] $($_.id)" }
        $and = Read-Host "Install these packages? (y/N)"
        if ($and -notmatch 'y') { return }
    }

    $results = foreach ($pkg in $packages) {
        Write-Host "Installing $($pkg.id)..." -NoNewline

        $args = @(
            "install", "--id", $pkg.id,
            "--exact", "--silent", "--no-upgrade",
            "--accept-source-agreements", "--accept-package-agreements"
        )

        if ($scope) { $args += "--scope", $scope }
        if ($pkg.override) { $args += "--override", $pkg.override }

        # Run
        & winget $args | Out-Null
        $exitCode = $LASTEXITCODE
        $success = ($exitCode -eq 0 -or $exitCode -eq 0x8a15001a) # 0 or "already installed"

        if ($success) {
            Write-Host " [OK]" -ForegroundColor Green
        } else {
            Write-Host " [FAIL: $exitCode]" -ForegroundColor Red
        }

        [PSCustomObject]@{
            Id       = $pkg.id
            Success  = $success
            ExitCode = $exitCode
        }
    }

    # Results
    $failed = $results | Where-Object { -not $_.Success }
    if ($failed) {
        Write-Host "`nError with installing:" -ForegroundColor Red
        $failed | ForEach-Object { Write-Host "  - $($_.Id) (код: $($_.ExitCode))" }
    } else {
        Write-Host "`nAll packages successfully installed." -ForegroundColor Green
    }
}

Install-Packages
