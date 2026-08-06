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
$Global:WingetInteractive = $false

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "           WINDOWS DOTFILES INSTALLER MODE                " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  [1] Semi-Unattended (Recommended): Auto-applies all steps," -ForegroundColor Yellow
Write-Host "      but runs Winget app installations interactively." -ForegroundColor Yellow
Write-Host "  [2] Full Unattended: Auto-applies all steps and installs apps" -ForegroundColor Yellow
Write-Host "      silently without prompt or intervention." -ForegroundColor Yellow
Write-Host "  [3] Attended (Step-by-Step): Prompts for confirmation before each" -ForegroundColor Yellow
Write-Host "      step and runs Winget app installations interactively." -ForegroundColor Yellow
Write-Host ""

$Choice = Read-Host "Select an option (1, 2, or 3) [Default: 1]"
if ([string]::IsNullOrWhiteSpace($Choice)) { $Choice = "1" }

switch ($Choice.Trim()) {
    "1" {
        $Global:Unattended = $true
        $Global:WingetInteractive = $true
        Write-Log "Semi-Unattended Mode selected: Auto-apply with interactive Winget installs."
    }
    "2" {
        $Global:Unattended = $true
        $Global:WingetInteractive = $false
        Write-Log "Full Unattended Mode selected: Everything automated and silent."
    }
    "3" {
        $Global:Unattended = $false
        $Global:WingetInteractive = $true
        Write-Log "Attended Mode selected: Step-by-step prompts with interactive installs."
    }
    default {
        $Global:Unattended = $true
        $Global:WingetInteractive = $true
        Write-Log "Invalid choice. Semi-Unattended Mode selected by default."
    }
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
. "$PSScriptRoot\scripts\06_personal_tweaks.ps1"
# Uninstalls (OneDrive, etc.)
. "$PSScriptRoot\scripts\07_uninstalls.ps1"
# Final steps
Write-Log "All modules executed successfully!"
Write-Host ""
if (Request-Confirmation "Do you want to restart your computer now to apply all changes?") {
    Write-Log "Restarting computer..."
    Restart-Computer -Force
} else {
    Write-Log "Please restart your system manually when convenient."
    Write-Host ""
    Read-Host "Press Enter to exit..."
}