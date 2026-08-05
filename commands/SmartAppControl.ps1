param(
    [switch]$GetInfo,
    [switch]$Status,
    [switch]$Enable,
    [switch]$Disable
)

# Metadata definitions
$Name = "Smart App Control (SAC) Disable"
$Description = "Disables Smart App Control (SAC) to prevent Windows from blocking unsigned or untrusted applications."

$WhyEnable = @(
    "Allow Unsigned Apps: Sets VerifiedAndReputablePolicyState to 0 to disable Smart App Control, allowing custom tools, scripts, and unsigned programs to run without blocks.",
    "Avoid Prompts: Eliminates false positive warnings and blocks on newly downloaded files."
)

$WhyDisable = @(
    "Restore Evaluation Mode: Sets VerifiedAndReputablePolicyState back to 2 (Evaluation Mode), allowing Windows to monitor and block potentially malicious files based on reputation."
)

function Get-CurrentStatus {
    try {
        $Path = "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy"
        $Value = Get-ItemPropertyValue -Path $Path -Name "VerifiedAndReputablePolicyState" -ErrorAction Stop
        if ($Value -eq 0) {
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
    Write-Host "Disabling Smart App Control (SAC)..." -ForegroundColor Cyan
    try {
        $Path = "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy"
        if (-not (Test-Path $Path)) {
            New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CI" -Name "Policy" -Force | Out-Null
        }
        Set-ItemProperty -Path $Path -Name "VerifiedAndReputablePolicyState" -Value 0 -Type DWord -Force
        Write-Host "Smart App Control disabled successfully. A system restart is required to apply changes." -ForegroundColor Green
    } catch {
        Write-Error "Failed to disable Smart App Control: $_"
        exit 1
    }
    exit
}

if ($Disable) {
    Write-Host "Restoring default Smart App Control settings (Evaluation Mode)..." -ForegroundColor Cyan
    try {
        $Path = "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy"
        if (-not (Test-Path $Path)) {
            New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CI" -Name "Policy" -Force | Out-Null
        }
        Set-ItemProperty -Path $Path -Name "VerifiedAndReputablePolicyState" -Value 2 -Type DWord -Force
        Write-Host "Smart App Control restored to Evaluation Mode successfully. A system restart is required to apply changes." -ForegroundColor Green
    } catch {
        Write-Error "Failed to restore Smart App Control settings: $_"
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
