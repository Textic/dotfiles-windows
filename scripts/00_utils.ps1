function Write-Log {
    param(
        [string]$Message
    )
    # Prints a formatted message with a timestamp
    $Time = Get-Date -Format "HH:mm:ss"
    Write-Host "[$Time] [INFO] $Message" -ForegroundColor Yellow
}

function Request-Confirmation {
    param(
        [string]$Question
    )
    # Asks the user for a Yes/No confirmation
    $Choice = Read-Host "$Question (y/n)"
    if ($Choice -match "^(y|Y)$") {
        return $true
    }
    return $false
}