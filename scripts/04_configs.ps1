Write-Log "Starting configuration files installation..."

if (Request-Confirmation "Do you want to install configurations (e.g., Windows Terminal settings.json)?") {
    
    # --- Windows Terminal Configuration ---
    # Path where you placed the file in your repository
    $RepoTerminalSettings = "$PSScriptRoot\..\config\terminal\settings.json"
    
    # Official Windows Terminal destination path on Windows
    $DestTerminalDir = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
    $DestTerminalSettings = "$DestTerminalDir\settings.json"

    if (Test-Path $RepoTerminalSettings) {
        Write-Log "Copying Windows Terminal settings.json..."
        
        # Create destination folder if it doesn't exist
        if (-not (Test-Path $DestTerminalDir)) {
            New-Item -ItemType Directory -Force -Path $DestTerminalDir | Out-Null
        }
        
        # Copy file and overwrite if it exists
        Copy-Item -Path $RepoTerminalSettings -Destination $DestTerminalSettings -Force
        Write-Log "Windows Terminal configuration installed successfully."
    } else {
        Write-Host "  [WARN] Base file not found at $RepoTerminalSettings" -ForegroundColor Yellow
    }
    
} else {
    Write-Log "Skipping configurations."
}