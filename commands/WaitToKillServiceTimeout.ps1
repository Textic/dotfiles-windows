param(
    [switch]$GetInfo,
    [switch]$Status,
    [switch]$Enable,
    [switch]$Disable
)

# Metadata definitions
$Name = "Shutdown Wait To Kill Timeouts"
$Description = "Sets the timeout (in milliseconds) Windows waits for services and user applications to stop before forcing termination during shutdown."

$WhyEnable = @(
    "Faster Shutdown: Reduces wait times to 2000ms (2 seconds), allowing Windows to shut down much quicker.",
    "Services & Apps: Configures both system services (WaitToKillServiceTimeout) and user applications (WaitToKillAppTimeout, HungAppTimeout).",
    "Prevents Hangs: Forces unresponsive software and services to terminate sooner instead of keeping the PC stuck on the shutdown screen."
)

$WhyDisable = @(
    "Safe Shutdown: Restores the default 5000ms (5 seconds) timeout for services and removes custom app termination limits, giving processes more time to save data."
)

function Get-CurrentStatus {
    try {
        $ServicePath = "HKLM:\SYSTEM\CurrentControlSet\Control"
        $AppPath = "HKCU:\Control Panel\Desktop"
        
        $ServiceTimeout = Get-ItemPropertyValue -Path $ServicePath -Name "WaitToKillServiceTimeout" -ErrorAction SilentlyContinue
        $AppTimeout = Get-ItemPropertyValue -Path $AppPath -Name "WaitToKillAppTimeout" -ErrorAction SilentlyContinue
        $HungTimeout = Get-ItemPropertyValue -Path $AppPath -Name "HungAppTimeout" -ErrorAction SilentlyContinue
        
        if ($ServiceTimeout -eq "2000" -and $AppTimeout -eq "2000" -and $HungTimeout -eq "2000") {
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
    Write-Host "Reducing shutdown timeouts to 2000ms for services and applications..." -ForegroundColor Cyan
    try {
        # 1. System Services (HKLM)
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "WaitToKillServiceTimeout" -Value "2000" -Force
        
        # 2. User Applications (HKCU)
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WaitToKillAppTimeout" -Value "2000" -Force
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "HungAppTimeout" -Value "2000" -Force
        
        Write-Host "Shutdown timeouts updated successfully." -ForegroundColor Green
    } catch {
        Write-Error "Failed to update shutdown timeouts: $_"
        exit 1
    }
    exit
}

if ($Disable) {
    Write-Host "Restoring default shutdown timeouts..." -ForegroundColor Cyan
    try {
        # 1. Restore Services to default 5000ms
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "WaitToKillServiceTimeout" -Value "5000" -Force
        
        # 2. Remove custom App timeouts to restore Windows defaults
        Remove-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WaitToKillAppTimeout" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "HungAppTimeout" -ErrorAction SilentlyContinue
        
        Write-Host "Shutdown timeouts restored to default successfully." -ForegroundColor Green
    } catch {
        Write-Error "Failed to restore shutdown timeouts: $_"
        exit 1
    }
    exit
}
