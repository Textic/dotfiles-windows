# Ensure utilities and administrator privileges
$ScriptRoot = $PSScriptRoot
if (-not (Get-Command "Write-Log" -ErrorAction SilentlyContinue)) {
    if (Test-Path "$ScriptRoot\00_utils.ps1") {
        . "$ScriptRoot\00_utils.ps1"
    }
}
if (Get-Command "Ensure-Admin" -ErrorAction SilentlyContinue) { Ensure-Admin }

Write-Log "Starting Windows Debloat module..."

if (Request-Confirmation "WARNING: Do you want to run the Debloat script (Remove bloatware, telemetry, AI, etc.)?") {
    Write-Log "Running Debloat script... This might take a few minutes."
    
    try {
        # Execute Win11Debloat
        & ([scriptblock]::Create((Invoke-RestMethod "https://debloat.raphi.re/"))) -Silent -CreateRestorePoint -RemoveHPApps -RemoveApps -RemoveCommApps -RemoveW11Outlook -RemoveGamingApps -DisableDVR -DisableStartRecommended -DisableStartPhoneLink -DisableTelemetry -DisableSuggestions -DisableEdgeAds -DisableSettings365Ads -DisableBing -DisableCopilot -DisableRecall -DisableEdgeAI -DisablePaintAI -DisableNotepadAI -DisableMouseAcceleration -DisableStickyKeys -ShowHiddenFolders -ShowKnownFileExt -EnableDarkMode -HideSearchTb -HideTaskview -HideChat -DisableWidgets -EnableEndTask -EnableWindowsSandbox -HideOnedrive
        
        Write-Log "Debloat process finished."
    }
    catch {
        Write-Host "  [ERROR] Debloat execution failed. Please check your internet connection." -ForegroundColor Red
        Write-Host "  Error details: $_" -ForegroundColor Red
    }
} else {
    Write-Log "Skipping debloat."
}