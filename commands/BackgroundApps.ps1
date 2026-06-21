param(
    [switch]$GetInfo,
    [switch]$Status,
    [switch]$Enable,
    [switch]$Disable
)

# Metadata definitions
$Name = "Background Apps Limit"
$Description = "Prevents Microsoft Store applications (Calculator, Mail, Weather, Xbox, etc.) from running in the background when not open."

$WhyEnable = @(
    "Memory Savings: Free up RAM by forcing background Windows Store apps to suspend when closed.",
    "CPU Performance: Prevents random background processing spikes from suspended applications."
)

$WhyDisable = @(
    "Enable Background Apps: Restores the default Windows behavior, allowing background apps to run and send notifications (e.g. Mail, Alarms) even when closed."
)

function Get-CurrentStatus {
    try {
        $Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"
        $Value = Get-ItemPropertyValue -Path $Path -Name "LetAppsRunInBackground" -ErrorAction Stop
        if ($Value -eq 2) {
            return $true
        }
        return $false
    } catch {
        return $false
    }
}

if ($GetInfo) {
    [PSCustomObject]@{
        Name          = $Name
        Description   = $Description
        WhyEnable     = $WhyEnable
        WhyDisable    = $WhyDisable
        Status        = (Get-CurrentStatus)
        ShowStatus    = $true
    }
    exit
}

if ($Status) {
    return (Get-CurrentStatus)
}

if ($Enable) {
    Write-Host "Forcing background app denial..." -ForegroundColor Cyan
    try {
        $ParentPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows"
        $Path = "$ParentPath\AppPrivacy"
        if (-not (Test-Path $Path)) {
            New-Item -Path $ParentPath -Name "AppPrivacy" -Force | Out-Null
        }
        Set-ItemProperty -Path $Path -Name "LetAppsRunInBackground" -Value 2 -Type DWord -Force
        Write-Host "Background apps restricted successfully." -ForegroundColor Green
    } catch {
        Write-Error "Failed to restrict background apps: $_"
        exit 1
    }
    exit
}

if ($Disable) {
    Write-Host "Restoring default background apps settings..." -ForegroundColor Cyan
    try {
        $Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"
        if (Test-Path $Path) {
            Remove-ItemProperty -Path $Path -Name "LetAppsRunInBackground" -ErrorAction SilentlyContinue
        }
        Write-Host "Background apps settings restored to default successfully." -ForegroundColor Green
    } catch {
        Write-Error "Failed to restore background apps settings: $_"
        exit 1
    }
    exit
}
