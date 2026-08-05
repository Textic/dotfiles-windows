param(
    [switch]$GetInfo,
    [switch]$Status,
    [switch]$Enable,
    [switch]$Disable
)

# Metadata definitions
$Name = "Xbox Game DVR & Screen Overlays"
$Description = "Disables Xbox Game DVR background recording and full-screen optimization overrides to prevent FPS drops and stuttering in games."

$WhyEnable = @(
    "Disable Recording: Sets GameDVR_Enabled to 0 to disable background game capturing and telemetry.",
    "FSE Optimization: Configures GameDVR_FSEBehaviorMode to 2 to bypass screen overlays that can cause input lag and micro-stuttering."
)

$WhyDisable = @(
    "Enable Game DVR: Restores GameDVR_Enabled to 1 and GameDVR_FSEBehaviorMode to 0 to enable Xbox Game Bar, screen recording, and full-screen game overlays."
)

function Get-CurrentStatus {
    try {
        $Path = "HKCU:\System\GameConfigStore"
        $Enabled = Get-ItemPropertyValue -Path $Path -Name "GameDVR_Enabled" -ErrorAction Stop
        $FSEBehavior = Get-ItemPropertyValue -Path $Path -Name "GameDVR_FSEBehaviorMode" -ErrorAction Stop
        $HonorUser = Get-ItemPropertyValue -Path $Path -Name "GameDVR_HonorUserFSEBehaviorMode" -ErrorAction Stop
        $DXGIHonor = Get-ItemPropertyValue -Path $Path -Name "GameDVR_DXGIHonorFSEWindowsCompatible" -ErrorAction Stop
        $EFSEFlags = Get-ItemPropertyValue -Path $Path -Name "GameDVR_EFSEFeatureFlags" -ErrorAction Stop

        if ($Enabled -eq 0 -and $FSEBehavior -eq 2 -and $HonorUser -eq 0 -and $DXGIHonor -eq 0 -and $EFSEFlags -eq 0) {
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
    Write-Host "Disabling Xbox Game DVR and screen overlays..." -ForegroundColor Cyan
    try {
        $Path = "HKCU:\System\GameConfigStore"
        if (-not (Test-Path $Path)) {
            New-Item -Path "HKCU:\System" -Name "GameConfigStore" -Force | Out-Null
        }
        Set-ItemProperty -Path $Path -Name "GameDVR_Enabled" -Value 0 -Type DWord -Force
        Set-ItemProperty -Path $Path -Name "GameDVR_FSEBehaviorMode" -Value 2 -Type DWord -Force
        Set-ItemProperty -Path $Path -Name "GameDVR_HonorUserFSEBehaviorMode" -Value 0 -Type DWord -Force
        Set-ItemProperty -Path $Path -Name "GameDVR_DXGIHonorFSEWindowsCompatible" -Value 0 -Type DWord -Force
        Set-ItemProperty -Path $Path -Name "GameDVR_EFSEFeatureFlags" -Value 0 -Type DWord -Force
        Write-Host "Xbox Game DVR and screen overlays disabled successfully." -ForegroundColor Green
    } catch {
        Write-Error "Failed to disable Xbox Game DVR: $_"
        exit 1
    }
    exit
}

if ($Disable) {
    Write-Host "Enabling Xbox Game DVR (restoring defaults)..." -ForegroundColor Cyan
    try {
        $Path = "HKCU:\System\GameConfigStore"
        if (-not (Test-Path $Path)) {
            New-Item -Path "HKCU:\System" -Name "GameConfigStore" -Force | Out-Null
        }
        Set-ItemProperty -Path $Path -Name "GameDVR_Enabled" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $Path -Name "GameDVR_FSEBehaviorMode" -Value 0 -Type DWord -Force
        Set-ItemProperty -Path $Path -Name "GameDVR_HonorUserFSEBehaviorMode" -Value 0 -Type DWord -Force
        Set-ItemProperty -Path $Path -Name "GameDVR_DXGIHonorFSEWindowsCompatible" -Value 0 -Type DWord -Force
        Set-ItemProperty -Path $Path -Name "GameDVR_EFSEFeatureFlags" -Value 0 -Type DWord -Force
        Write-Host "Xbox Game DVR enabled and defaults restored successfully." -ForegroundColor Green
    } catch {
        Write-Error "Failed to restore Xbox Game DVR settings: $_"
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
