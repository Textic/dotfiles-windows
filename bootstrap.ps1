<#
.SYNOPSIS
    Remote bootstrap installer for Windows Dotfiles repository.
.DESCRIPTION
    Downloads the latest version of the repository from GitHub, extracts it to a temporary directory,
    and launches the modular installer with Administrator privileges.
.EXAMPLE
    irm https://raw.githubusercontent.com/Textic/dotfiles-windows/main/bootstrap.ps1 | iex
#>

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Ensure TLS 1.2 / TLS 1.3 support for secure downloads
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072 -bor 12288

Clear-Host
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "        WINDOWS DOTFILES - REMOTE BOOTSTRAPPER            " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

# Ensure Administrator Privileges
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $IsAdmin) {
    Write-Host "[!] Administrator privileges required. Requesting elevation..." -ForegroundColor Yellow
    try {
        $BootstrapUrl = "https://raw.githubusercontent.com/Textic/dotfiles-windows/main/bootstrap.ps1"
        $Arguments = "-NoProfile -ExecutionPolicy Bypass -Command `"& ([scriptblock]::Create((Invoke-RestMethod '$BootstrapUrl')))`""
        Start-Process -FilePath "powershell.exe" -ArgumentList $Arguments -Verb RunAs
        exit 0
    } catch {
        Write-Host "[ERROR] Elevation was denied or failed. Please run PowerShell as Administrator." -ForegroundColor Red
        Write-Host ""
        Read-Host "Press Enter to exit..."
        exit 1
    }
}

# Repository & Directory configuration
$RepoZipUrl = "https://github.com/Textic/dotfiles-windows/archive/refs/heads/main.zip"
$TempBaseDir = "$env:TEMP\dotfiles-setup-$([guid]::NewGuid().ToString().Substring(0,8))"
$ZipPath = "$TempBaseDir\repo.zip"
$ExtractPath = "$TempBaseDir\extracted"

try {
    # Create temporary working directory
    New-Item -ItemType Directory -Path $TempBaseDir -Force | Out-Null

    Write-Host "[+] Downloading repository archive from GitHub..." -ForegroundColor Cyan
    Invoke-RestMethod -Uri $RepoZipUrl -OutFile $ZipPath

    Write-Host "[+] Extracting archive files..." -ForegroundColor Cyan
    Expand-Archive -Path $ZipPath -DestinationPath $ExtractPath -Force

    # Locate root directory of extracted content
    $RepoRootDir = Get-ChildItem -Path $ExtractPath -Directory | Select-Object -First 1
    if (-not $RepoRootDir -or -not (Test-Path "$($RepoRootDir.FullName)\install.ps1")) {
        throw "Could not locate install.ps1 in the downloaded archive."
    }

    Write-Host "[+] Launching installer..." -ForegroundColor Green
    Write-Host ""
    Start-Sleep -Seconds 1

    # Execute installer in the extracted directory
    Push-Location $RepoRootDir.FullName
    try {
        & "$($RepoRootDir.FullName)\install.ps1"
    } finally {
        Pop-Location
    }
}
catch {
    Write-Host ""
    Write-Host "[ERROR] Bootstrapping failed: $_" -ForegroundColor Red
    Write-Host ""
    Read-Host "Press Enter to exit..."
    exit 1
}
finally {
    # Clean up temporary archive files after installation finishes
    if (Test-Path $TempBaseDir) {
        Remove-Item -Path $TempBaseDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
