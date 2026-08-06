param(
    [switch]$GetInfo,
    [switch]$Status,
    [switch]$Enable,
    [switch]$Disable
)

# Metadata definitions
$Name = "Ultimate Performance Power Plan"
$Description = "Enables and activates the Ultimate Performance power scheme to eliminate micro-latency and maximize hardware responsiveness."

$WhyEnable = @(
    "Maximum Performance: Disables all power-saving throttling, core parking, and disk spin-down states to provide maximum responsiveness.",
    "Hardware Utilization: Dedicates full resources to active tasks (recommended for desktops or plugged-in gaming/workstation laptops)."
)

$WhyDisable = @(
    "Power Savings: Restores the default Balanced power scheme, allowing the CPU and peripherals to enter low-power states to save energy and battery."
)

function Get-CurrentStatus {
    try {
        $Active = powercfg /getactivescheme
        if ($Active -match "e9a42b02-d5df-448d-aa00-03f14749eb61") {
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
    Write-Host "Enabling Ultimate Performance Power Plan..." -ForegroundColor Cyan
    try {
        $Schemes = powercfg /l
        if ($Schemes -notmatch "e9a42b02-d5df-448d-aa00-03f14749eb61") {
            powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 | Out-Null
        }
        powercfg /setactive e9a42b02-d5df-448d-aa00-03f14749eb61 | Out-Null
        Write-Host "Ultimate Performance Power Plan activated successfully." -ForegroundColor Green
    } catch {
        Write-Error "Failed to enable Ultimate Performance Power Plan: $_"
        exit 1
    }
    exit
}

if ($Disable) {
    Write-Host "Restoring default Balanced Power Plan..." -ForegroundColor Cyan
    try {
        # Balanced scheme GUID is 381b4222-f694-41f0-9685-ff5bb260df2e
        powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e | Out-Null
        Write-Host "Balanced Power Plan restored successfully." -ForegroundColor Green
    } catch {
        Write-Error "Failed to restore Balanced Power Plan: $_"
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
