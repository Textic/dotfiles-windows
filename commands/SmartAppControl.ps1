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
