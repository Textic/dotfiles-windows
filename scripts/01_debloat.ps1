# File: scripts/03_debloat.ps1
# Description: Runs the specified Windows Debloat command.
# Warning: This downloads and runs a script from the internet.

Write-Log "Starting Windows Debloat module..."

if (Request-Confirmation "WARNING: Do you want to run the Debloat script (Remove bloatware, telemetry, AI, etc.)?") {
    Write-Log "Running Debloat script... This might take a few minutes."
    
    try {
        # Your specific command from Debloat.ps1
        # It creates a restore point automatically (-CreateRestorePoint), which is good practice.
        & ([scriptblock]::Create((Invoke-RestMethod "https://debloat.raphi.re/"))) -Silent -CreateRestorePoint -RemoveHPApps -RemoveApps -RemoveCommApps -RemoveW11Outlook -RemoveGamingApps -DisableDVR -DisableStartRecommended -DisableStartPhoneLink -DisableTelemetry -DisableSuggestions -DisableEdgeAds -DisableSettings365Ads -DisableBing -DisableCopilot -DisableRecall -DisableEdgeAI -DisablePaintAI -DisableNotepadAI -DisableMouseAcceleration -DisableStickyKeys -ShowHiddenFolders -ShowKnownFileExt -EnableDarkMode -HideSearchTb -HideTaskview -HideChat -DisableWidgets -EnableEndTask
        
        Write-Log "Debloat process finished."
    }
    catch {
        Write-Host "  [ERROR] Debloat execution failed. Please check your internet connection." -ForegroundColor Red
        Write-Host "  Error details: $_" -ForegroundColor Red
    }
} else {
    Write-Log "Skipping debloat."
}