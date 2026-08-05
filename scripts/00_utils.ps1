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
    if ($Global:Unattended) {
        Write-Host "[$Question] -> Auto-Confirmed: Yes" -ForegroundColor Green
        return $true
    }
    # Asks the user for a Yes/No confirmation
    $Choice = Read-Host "$Question (y/n)"
    if ($Choice -match "^(y|Y)$") {
        return $true
    }
    return $false
}

function Ensure-Admin {
    $Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object Security.Principal.WindowsPrincipal($Identity)
    $IsAdmin = $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $IsAdmin) {
        Write-Host "Administrator privileges are required for this script." -ForegroundColor Yellow
        Write-Host "Attempting to elevate..." -ForegroundColor Yellow
        try {
            $Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
            Start-Process -FilePath "powershell.exe" -ArgumentList $Arguments -Verb RunAs -ErrorAction Stop
            exit 0
        } catch {
            Write-Host "UAC elevation request was denied or failed." -ForegroundColor Red
            Write-Host "Please run this script from an elevated PowerShell window (Run as Administrator)." -ForegroundColor Red
            Write-Host ""
            Read-Host "Press Enter to exit..."
            exit 1
        }
    }
}