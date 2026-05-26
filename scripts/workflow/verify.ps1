param(
    [string]$Service = "all",
    [switch]$IncludeUi,
    [switch]$NoRace
)

$ErrorActionPreference = "Stop"
if (Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
    $PSNativeCommandUseErrorActionPreference = $false
}

$Root = Resolve-Path (Join-Path $PSScriptRoot "..\..")

function Get-ProductServices {
    $dirs = Get-ChildItem -Path $Root -Directory -Exclude ".*", "vendor", "scripts", "docs"
    $results = @()
    foreach ($dir in $dirs) {
        if (Test-Path (Join-Path $dir.FullName "go.mod")) {
            $results += $dir.Name
        }
    }
    return $results
}

if ($Service -eq "all") {
    $Selected = Get-ProductServices
    if ($IncludeUi) {
        $Selected += "ui"
    }
} else {
    $Selected = @($Service)
}

$Failures = @()

function Invoke-CmdChecked {
    param(
        [Parameter(Mandatory=$true)][string]$Command,
        [Parameter(Mandatory=$true)][string]$LogPath
    )

    cmd /c "$Command > `"$LogPath`" 2>&1"
    return $LASTEXITCODE
}

function Get-PackageManager {
    param([Parameter(Mandatory=$true)][string]$Dir)

    if ((Test-Path (Join-Path $Dir "pnpm-lock.yaml")) -and (Get-Command pnpm -ErrorAction SilentlyContinue)) {
        return "pnpm"
    }
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        return "npm"
    }
    return $null
}

function Test-NpmScript {
    param(
        [Parameter(Mandatory=$true)][string]$Dir,
        [Parameter(Mandatory=$true)][string]$Script
    )

    $PackageJson = Join-Path $Dir "package.json"
    if (-not (Test-Path $PackageJson)) {
        return $false
    }
    $Package = Get-Content $PackageJson -Raw | ConvertFrom-Json
    return $null -ne $Package.scripts.$Script
}

foreach ($Name in $Selected) {
    if ($Name -eq "ui") {
        $Dir = Join-Path $Root "amdox-netdisk-ui"
        $LogDir = Join-Path $Root ".agent\logs\ui"
        New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

        Write-Host "== ui =="
        $PackageManager = Get-PackageManager -Dir $Dir
        if (-not $PackageManager) {
            $Failures += "ui package manager"
            Write-Host "npm or pnpm is required for UI verification"
            continue
        }

        Push-Location $Dir
        try {
            foreach ($Script in @("lint", "test", "build")) {
                if (-not (Test-NpmScript -Dir $Dir -Script $Script)) {
                    Write-Host "$Script skipped: package.json has no script"
                    continue
                }

                $Log = Join-Path $LogDir "$Script.ps1.txt"
                $ExitCode = Invoke-CmdChecked "$PackageManager run $Script" $Log
                if ($ExitCode -ne 0) {
                    $Failures += "ui $Script"
                    Get-Content $Log -TotalCount 120
                } else {
                    Write-Host "$Script passed"
                }
            }
        } finally {
            Pop-Location
        }
        continue
    }

    $Dir = Join-Path $Root $Name
    $Entry = "main.go"
    if (Test-Path (Join-Path $Dir "$Name.go")) {
        $Entry = "$Name.go"
    }
    $LogDir = Join-Path $Root ".agent\logs\$Name"
    New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

    Write-Host "== $Name =="

    $Go = Get-Command go -ErrorAction SilentlyContinue
    if (-not $Go) {
        throw "Go is not available in PowerShell PATH"
    }

    Push-Location $Dir
    try {
        $BuildLog = Join-Path $LogDir "build.ps1.txt"
        $OutFile = Join-Path $Root "bin\$Name.exe"
        $ExitCode = Invoke-CmdChecked "go build -o `"$OutFile`" $Entry" $BuildLog
        if ($ExitCode -ne 0) {
            $Failures += "$Name build"
            Get-Content $BuildLog -TotalCount 80
            continue
        }
        Write-Host "build passed"

        $VetLog = Join-Path $LogDir "vet.ps1.txt"
        $ExitCode = Invoke-CmdChecked "go vet ./..." $VetLog
        if ($ExitCode -ne 0) {
            $Failures += "$Name vet"
            Get-Content $VetLog -TotalCount 80
        } else {
            Write-Host "vet passed"
        }

        $TestLog = Join-Path $LogDir "test.ps1.txt"
        if ($NoRace) {
            $ExitCode = Invoke-CmdChecked "go test ./..." $TestLog
        } else {
            $ExitCode = Invoke-CmdChecked "go test ./... -race" $TestLog
            if ($ExitCode -ne 0 -and (Select-String -Path $TestLog -Pattern "-race requires cgo" -Quiet)) {
                Write-Host "race unavailable; retrying without -race"
                $ExitCode = Invoke-CmdChecked "go test ./..." $TestLog
            }
        }

        if ($ExitCode -ne 0) {
            $Failures += "$Name test"
            Get-Content $TestLog -TotalCount 120
        } else {
            Write-Host "test passed"
        }
    } finally {
        Pop-Location
    }
}

if ($Failures.Count -gt 0) {
    Write-Host "Failures: $($Failures -join ', ')"
    exit 1
}

Write-Host "All selected services passed"
