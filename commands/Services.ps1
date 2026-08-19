param(
    [switch]$GetInfo,
    [switch]$Status,
    [switch]$Enable,
    [switch]$Disable
)

# Metadata definitions
$Name = "Windows Services Optimization"
$Description = "Stops and disables unnecessary telemetry, diagnostic, error reporting, delivery optimization, compatibility, printing, telephony, sensor, and caching services."

$WhyEnable = @(
    "Telemetry, Analytics & Diagnostics (DiagTrack, dmwappushservice, DPS, InventorySvc, wuqisvc, whesvc): Disables diagnostic logging, telemetry routing, compatibility appraisal, usage insights, and Windows Health monitoring to protect privacy and free up background resources.",
    "Delivery Optimization (DoSvc): Disables P2P update sharing and background cloud bandwidth usage.",
    "Error Reporting & Compatibility (WerSvc, PcaSvc): Disables automated crash reporting to Microsoft and Program Compatibility Assistant popups.",
    "Printing & Sensors (Spooler, SensorService): Disables the print spooler (for systems without printers) and sensor management (ambient light, auto-rotation).",
    "Telephony & Phone (TapiSrv, PhoneSvc): Disables legacy telephony/modem services and Phone Link background services.",
    "Disk Caching & WebDAV (SysMain, WebClient): Disables Superfetch caching (unnecessary on SSDs/NVMes) and legacy WebDAV network client."
)

$WhyDisable = @(
    "Restore Default Services: Restores startup types for all managed services back to their standard defaults (Automatic/Manual) and starts them."
)

# Target services definition list
$ServicesToManage = @(
    # --- Telemetry & Diagnostics ---
    @{ Name = "DiagTrack";        DefaultStartup = "Automatic"; Description = "Connected User Experiences and Telemetry" },
    @{ Name = "dmwappushservice"; DefaultStartup = "Manual";    Description = "WAP Push Message Routing Service (Telemetry)" },
    @{ Name = "DPS";              DefaultStartup = "Automatic"; Description = "Diagnostic Policy Service" },
    @{ Name = "InventorySvc";     DefaultStartup = "Manual";    Description = "Inventory and Compatibility Appraisal Service" },
    @{ Name = "wuqisvc";          DefaultStartup = "Manual";    Description = "Microsoft Usage and Quality Insights" },
    @{ Name = "whesvc";           DefaultStartup = "Automatic"; Description = "Windows Health and Optimized Experiences" },
    @{ Name = "WerSvc";           DefaultStartup = "Manual";    Description = "Windows Error Reporting Service" },

    # --- Updates & Compatibility ---
    @{ Name = "DoSvc";            DefaultStartup = "Automatic"; Description = "Delivery Optimization" },
    @{ Name = "PcaSvc";           DefaultStartup = "Automatic"; Description = "Program Compatibility Assistant Service" },

    # --- Hardware, Printing & Sensors ---
    @{ Name = "Spooler";          DefaultStartup = "Automatic"; Description = "Print Spooler" },
    @{ Name = "SensorService";    DefaultStartup = "Manual";    Description = "Sensor Service" },

    # --- Telephony & Phone Link ---
    @{ Name = "TapiSrv";          DefaultStartup = "Manual";    Description = "Telephony" },
    @{ Name = "PhoneSvc";         DefaultStartup = "Manual";    Description = "Phone Service" },

    # --- System & Network ---
    @{ Name = "SysMain";          DefaultStartup = "Automatic"; Description = "SysMain (Superfetch)" },
    @{ Name = "WebClient";        DefaultStartup = "Manual";    Description = "WebClient" }
)

function Resolve-ServiceName {
    param([string]$Name)
    if (Get-Service -Name $Name -ErrorAction SilentlyContinue) {
        return $Name
    }
    if ($Name -eq "TapiSrv" -and (Get-Service -Name "Telephony" -ErrorAction SilentlyContinue)) {
        return "Telephony"
    }
    return $null
}

function Get-ServiceStartupState {
    param([string]$ServiceName)
    try {
        $RegVal = Get-ItemPropertyValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$ServiceName" -Name "Start" -ErrorAction SilentlyContinue
        if ($null -ne $RegVal) {
            if ($RegVal -eq 4) { return "Disabled" }
            if ($RegVal -eq 2) { return "Automatic" }
            if ($RegVal -eq 3) { return "Manual" }
        }
    } catch {}

    try {
        $Svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($Svc) {
            return $Svc.StartType.ToString()
        }
    } catch {}

    return $null
}

function Set-ServiceStartupState {
    param(
        [string]$ServiceName,
        [string]$StartupType # "Disabled", "Automatic", "Manual"
    )

    $RegValueMap = @{
        "Automatic" = 2
        "Manual"    = 3
        "Disabled"  = 4
    }

    # 1. Try standard Set-Service cmdlet
    try {
        Set-Service -Name $ServiceName -StartupType $StartupType -ErrorAction Stop
        return $true
    } catch {
        # 2. Fallback: Direct Registry modification for TrustedInstaller/protected services (like DoSvc)
        try {
            $RegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$ServiceName"
            if (Test-Path $RegPath) {
                $RegVal = $RegValueMap[$StartupType]
                Set-ItemProperty -Path $RegPath -Name "Start" -Value $RegVal -Type DWord -Force -ErrorAction Stop
                return $true
            }
        } catch {
            Write-Host "    [!] Registry fallback failed for $($ServiceName): $_" -ForegroundColor Red
            return $false
        }
    }
    return $false
}

function Get-CurrentStatus {
    try {
        $AllDisabled = $true
        $FoundAny = $false
        foreach ($SvcDef in $ServicesToManage) {
            $ActualName = Resolve-ServiceName -Name $SvcDef.Name
            if ($ActualName) {
                $FoundAny = $true
                $State = Get-ServiceStartupState -ServiceName $ActualName
                if ($State -ne "Disabled") {
                    $AllDisabled = $false
                    break
                }
            }
        }
        return ($FoundAny -and $AllDisabled)
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
    Write-Host "Stopping and disabling target Windows services..." -ForegroundColor Cyan
    $Errors = 0
    foreach ($SvcDef in $ServicesToManage) {
        $ActualName = Resolve-ServiceName -Name $SvcDef.Name
        if ($ActualName) {
            Write-Host "  -> Stopping and disabling $($SvcDef.Description) ($ActualName)..." -ForegroundColor Gray
            Stop-Service -Name $ActualName -Force -ErrorAction SilentlyContinue
            $Ok = Set-ServiceStartupState -ServiceName $ActualName -StartupType "Disabled"
            if (-not $Ok) {
                $Errors++
            }
        } else {
            Write-Host "  [SKIP] Service '$($SvcDef.Name)' not found on this system." -ForegroundColor DarkGray
        }
    }
    if ($Errors -eq 0) {
        Write-Host "Target services stopped and set to Disabled successfully." -ForegroundColor Green
    } else {
        Write-Host "Target services processed with $Errors warning(s)." -ForegroundColor Yellow
    }
    exit
}

if ($Disable) {
    Write-Host "Restoring target Windows services to default settings..." -ForegroundColor Cyan
    $Errors = 0
    foreach ($SvcDef in $ServicesToManage) {
        $ActualName = Resolve-ServiceName -Name $SvcDef.Name
        if ($ActualName) {
            $DefaultStartup = $SvcDef.DefaultStartup
            Write-Host "  -> Restoring $($SvcDef.Description) ($ActualName) to $DefaultStartup..." -ForegroundColor Gray
            $Ok = Set-ServiceStartupState -ServiceName $ActualName -StartupType $DefaultStartup
            if ($Ok) {
                if ($DefaultStartup -eq "Automatic") {
                    Start-Service -Name $ActualName -ErrorAction SilentlyContinue
                }
            } else {
                $Errors++
            }
        } else {
            Write-Host "  [SKIP] Service '$($SvcDef.Name)' not found on this system." -ForegroundColor DarkGray
        }
    }
    if ($Errors -eq 0) {
        Write-Host "Target services restored to defaults successfully." -ForegroundColor Green
    } else {
        Write-Host "Target services restored with $Errors warning(s)." -ForegroundColor Yellow
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

    $Question = if ($Current) { "Do you want to DISABLE '$Name' (restore defaults)?" } else { "Do you want to ENABLE '$Name' (stop & disable services)?" }
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
