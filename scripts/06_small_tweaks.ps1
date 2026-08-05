# File: scripts/06_small_tweaks.ps1
# Description: Applies small miscellaneous registry tweaks and UI fixes.

# Ensure utilities and administrator privileges
$ScriptRoot = $PSScriptRoot
if (-not (Get-Command "Write-Log" -ErrorAction SilentlyContinue)) {
    if (Test-Path "$ScriptRoot\00_utils.ps1") {
        . "$ScriptRoot\00_utils.ps1"
    }
}
if (Get-Command "Ensure-Admin" -ErrorAction SilentlyContinue) { Ensure-Admin }

Write-Log "Starting small tweaks module..."

# Placeholder for future minor tweaks
Write-Log "No small tweaks currently configured."
