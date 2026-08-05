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

# Interactive fallback when executed directly without parameters
if (-not $PSBoundParameters.Count) {
    $ScriptRoot = $PSScriptRoot
    if (-not (Get-Command "Write-Log" -ErrorAction SilentlyContinue)) {
        if (Test-Path "$ScriptRoot\..\scripts\00_utils.ps1") {
            . "$ScriptRoot\..\scripts\00_utils.ps1"
        }
    }
    if (Get-Command "Ensure-Admin" -ErrorAction SilentlyContinue) { Ensure-Admin }

    $Current = Get-CurrentStatus
    Write-Host "--- Tweak: $Name ---" -ForegroundColor Cyan
    Write-Host "Description: $Description" -ForegroundColor White

    $StatusStr = if ($Current) { "ACTIVE" } else { "INACTIVE" }
    $StatusColor = if ($Current) { "Green" } else { "Yellow" }
    Write-Host "Current Status: [$StatusStr]" -ForegroundColor $StatusColor
    Write-Host ""

    Write-Host "[+] WHEN YOU SHOULD ENABLE IT:" -ForegroundColor Green
    foreach ($Point in $WhyEnable) { Write-Host "  * $Point" -ForegroundColor Gray }
    Write-Host ""

    Write-Host "[-] WHEN YOU SHOULD DISABLE IT:" -ForegroundColor Red
    foreach ($Point in $WhyDisable) { Write-Host "  * $Point" -ForegroundColor Gray }
    Write-Host ""

    $Question = if ($Current) { "Do you want to DISABLE '$Name'?" } else { "Do you want to ENABLE '$Name'?" }
    $ActionToRun = if ($Current) { "-Disable" } else { "-Enable" }

    if (Get-Command "Request-Confirmation" -ErrorAction SilentlyContinue) {
        $Confirmed = Request-Confirmation $Question
    } else {
        $Choice = Read-Host "$Question (y/n)"
        $Confirmed = $Choice -match "^(y|Y)$"
    }

    if ($Confirmed) {
        Write-Host ""
        if ($ActionToRun -eq "-Disable") {
            & $PSCommandPath -Disable
        } else {
            & $PSCommandPath -Enable
        }
    } else {
        Write-Host "Skipping tweak '$Name'." -ForegroundColor Yellow
    }
}
