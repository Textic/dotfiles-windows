# Ensure we stop on errors (similar to set -e in bash)
$ErrorActionPreference = "Stop"

Clear-Host
Write-Host "Starting modular installation for Windows..." -ForegroundColor Cyan

# Import utilities
. "$PSScriptRoot\scripts\00_utils.ps1"

Write-Log "Imported utilities successfully."

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