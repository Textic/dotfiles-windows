param(
    [switch]$GetInfo,
    [switch]$Status,
    [switch]$Enable,
    [switch]$Disable
)

# Metadata definitions
$Name = "Network Throttling & System Responsiveness"
$Description = "Optimizes network responsiveness for gaming by disabling network throttling and prioritizing active applications."

$WhyEnable = @(
    "Disable Throttling: Sets NetworkThrottlingIndex to ffffffff to prevent network packet throttling, helping to reduce ping spikes in online games.",
    "Maximum Responsiveness: Sets SystemResponsiveness to 0, dedicating 100% CPU resources to active games and foreground apps instead of reserving 20% for background services."
)

$WhyDisable = @(
    "Default Throttling: Restores the default NetworkThrottlingIndex value to 10.",
    "Balanced CPU Reservation: Restores SystemResponsiveness to 20, reserving 20% CPU resources for background processes to ensure system task stability."
)

function Get-CurrentStatus {
    try {
        $Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
        $ThrottlingIndex = Get-ItemPropertyValue -Path $Path -Name "NetworkThrottlingIndex" -ErrorAction Stop
        $Responsiveness = Get-ItemPropertyValue -Path $Path -Name "SystemResponsiveness" -ErrorAction Stop
        
        # 4294967295 is 0xffffffff (unsigned 32-bit int max / signed -1)
        if (($ThrottlingIndex -eq 4294967295 -or $ThrottlingIndex -eq -1) -and $Responsiveness -eq 0) {
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
    Write-Host "Disabling network throttling and maximizing system responsiveness..." -ForegroundColor Cyan
    try {
        $Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
        Set-ItemProperty -Path $Path -Name "NetworkThrottlingIndex" -Value 0xffffffff -Type DWord -Force
        Set-ItemProperty -Path $Path -Name "SystemResponsiveness" -Value 0 -Type DWord -Force
        Write-Host "Network throttling disabled and system responsiveness optimized successfully." -ForegroundColor Green
    } catch {
        Write-Error "Failed to optimize network and system responsiveness: $_"
        exit 1
    }
    exit
}

if ($Disable) {
    Write-Host "Restoring default network throttling and system responsiveness values..." -ForegroundColor Cyan
    try {
        $Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
        Set-ItemProperty -Path $Path -Name "NetworkThrottlingIndex" -Value 10 -Type DWord -Force
        Set-ItemProperty -Path $Path -Name "SystemResponsiveness" -Value 20 -Type DWord -Force
        Write-Host "Network throttling and system responsiveness restored to default successfully." -ForegroundColor Green
    } catch {
        Write-Error "Failed to restore network and system responsiveness: $_"
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
