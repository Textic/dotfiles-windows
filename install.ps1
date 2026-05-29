# Ensure we stop on errors (similar to set -e in bash)
$ErrorActionPreference = "Stop"

Write-Host "Starting modular installation for Windows..." -ForegroundColor Cyan

# Get the directory where this script is located
$ScriptRoot = $PSScriptRoot

# Import utilities
. "$ScriptRoot\scripts\00_utils.ps1"

Write-Log "Imported utilities successfully."

# --- Module Execution ---

# Debloat
. "$ScriptRoot\scripts\01_debloat.ps1"
# Install Packages (Winget)
. "$ScriptRoot\scripts\02_packages.ps1"
# Install Fonts
. "$ScriptRoot\scripts\03_fonts.ps1"
# Install Configurations
. "$ScriptRoot\scripts\04_configs.ps1"
# Individual Tweaks and Commands
. "$ScriptRoot\scripts\05_tweaks.ps1"
# Final steps
Write-Log "All modules executed successfully! Please restart your terminal/system."