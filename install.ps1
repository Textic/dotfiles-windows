# Ensure we stop on errors (similar to set -e in bash)
$ErrorActionPreference = "Stop"

# Import utilities and ensure Administrator privileges
. "$PSScriptRoot\scripts\00_utils.ps1"
Ensure-Admin

Clear-Host
Write-Host "Starting modular installation for Windows..." -ForegroundColor Cyan

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
# Small Miscellaneous Tweaks
. "$PSScriptRoot\scripts\06_small_tweaks.ps1"
# Final steps
Write-Log "All modules executed successfully! Please restart your terminal/system."
Write-Host ""
Read-Host "Press Enter to exit..."