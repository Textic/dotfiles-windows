# Ensure we stop on errors (similar to set -e in bash)
$ErrorActionPreference = "Stop"

# Check for Administrator privileges
$Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object Security.Principal.WindowsPrincipal($Identity)
$IsAdmin = $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    Clear-Host
    Write-Host "==========================================================" -ForegroundColor Red
    Write-Host "   ERROR: ADMINISTRATOR PRIVILEGES REQUIRED               " -ForegroundColor Red
    Write-Host "==========================================================" -ForegroundColor Red
    Write-Host "This installer must be run from an elevated PowerShell console." -ForegroundColor Yellow
    Write-Host "Please close this window, right-click PowerShell, choose" -ForegroundColor Yellow
    Write-Host "'Run as Administrator', and try again." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit..."
    exit 1
}

Clear-Host
Write-Host "Starting modular installation for Windows..." -ForegroundColor Cyan

# Import utilities
. "$PSScriptRoot\scripts\00_utils.ps1"

Write-Log "Imported utilities successfully."

# --- Setup Mode Selection ---
$Global:Unattended = $false
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "           WINDOWS DOTFILES INSTALLER MODE                " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""
$Choice = Read-Host "Do you want to run in Unattended Mode (auto-confirm and apply all steps)? (y/n)"
if ($Choice -match "^(y|Y)$") {
    $Global:Unattended = $true
    Write-Log "Unattended Mode enabled. Everything will be auto-applied."
} else {
    $Global:Unattended = $false
    Write-Log "Step-by-Step Mode enabled. You will be prompted for each option."
}
Write-Host ""
Start-Sleep -Seconds 1

# --- Module Execution ---

# Debloat
. "$PSScriptRoot\scripts\01_debloat.ps1"
# Install Packages (Winget)
. "$PSScriptRoot\scripts\02_packages.ps1"
# Install Fonts
. "$PSScriptRoot\scripts\03_fonts.ps1"
# Install Configurations
. "$PSScriptRoot\scripts\04_configs.ps1"
# Individual Tweaks and Commands
. "$PSScriptRoot\scripts\05_tweaks.ps1"
# Final steps
Write-Log "All modules executed successfully! Please restart your terminal/system."