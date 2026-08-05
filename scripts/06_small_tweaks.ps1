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

if (Request-Confirmation "Do you want to apply small system tweaks (e.g. hide desktop build watermark)?") {
    try {
        # 1. Hide Windows desktop build watermark (PaintDesktopVersion = 0)
        $DesktopPath = "HKCU:\Control Panel\Desktop"
        Set-ItemProperty -Path $DesktopPath -Name "PaintDesktopVersion" -Value 0 -Type DWord -Force
        Write-Host "  * Windows desktop watermark hidden (PaintDesktopVersion = 0)." -ForegroundColor Green

        Write-Log "Small tweaks applied successfully."
    } catch {
        Write-Host "  [ERROR] Failed to apply small tweaks: $_" -ForegroundColor Red
    }
} else {
    Write-Log "Skipping small tweaks."
}
