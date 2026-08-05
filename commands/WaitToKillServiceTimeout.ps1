param(
    [switch]$GetInfo,
    [switch]$Status,
    [switch]$Enable,
    [switch]$Disable
)

# Metadata definitions
$Name = "Service Shutdown Timeout"
$Description = "Configures the timeout Windows waits for system services to stop before forcing termination during shutdown."

$WhyEnable = @(
    "Faster Shutdown: Reduces the service wait time to 2000ms (2 seconds), allowing Windows to shut down much quicker.",
    "Prevents Hangs: Forces unresponsive services to terminate sooner instead of keeping the PC stuck on the shutdown screen."
)

$WhyDisable = @(
    "Safe Shutdown: Restores the default 5000ms (5 seconds) timeout for services, giving them more time to complete saving data."
)

function Get-CurrentStatus {
    try {
        $Path = "HKLM:\SYSTEM\CurrentControlSet\Control"
        $Timeout = Get-ItemPropertyValue -Path $Path -Name "WaitToKillServiceTimeout" -ErrorAction Stop
        if ($Timeout -eq "2000") {
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
    Write-Host "Reducing service shutdown timeout to 2000ms..." -ForegroundColor Cyan
    try {
        $Path = "HKLM:\SYSTEM\CurrentControlSet\Control"
        Set-ItemProperty -Path $Path -Name "WaitToKillServiceTimeout" -Value "2000" -Force
        Write-Host "Service shutdown timeout updated successfully." -ForegroundColor Green
    } catch {
        Write-Error "Failed to update service shutdown timeout: $_"
        exit 1
    }
    exit
}

if ($Disable) {
    Write-Host "Restoring default service shutdown timeout..." -ForegroundColor Cyan
    try {
        $Path = "HKLM:\SYSTEM\CurrentControlSet\Control"
        Set-ItemProperty -Path $Path -Name "WaitToKillServiceTimeout" -Value "5000" -Force
        Write-Host "Service shutdown timeout restored to default successfully." -ForegroundColor Green
    } catch {
        Write-Error "Failed to restore service shutdown timeout: $_"
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
