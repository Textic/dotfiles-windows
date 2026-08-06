# File: scripts/06_personal_tweaks.ps1
# Description: Applies personal miscellaneous registry tweaks (taskbar, desktop, date/time formats, and script execution policy).

# Ensure utilities and administrator privileges
$ScriptRoot = $PSScriptRoot
if (-not (Get-Command "Write-Log" -ErrorAction SilentlyContinue)) {
    if (Test-Path "$ScriptRoot\00_utils.ps1") {
        . "$ScriptRoot\00_utils.ps1"
    }
}
if (Get-Command "Ensure-Admin" -ErrorAction SilentlyContinue) { Ensure-Admin }

Write-Log "Starting personal tweaks module..."

$NeedExplorerRestart = $false

# Status helper functions
function Get-MMTaskbarStatus {
    try {
        $AdvancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        $Val = Get-ItemPropertyValue -Path $AdvancedPath -Name "MMTaskbarEnabled" -ErrorAction Stop
        return $Val -eq 0
    } catch {
        return $false
    }
}

function Get-AutoHideStatus {
    try {
        $StuckPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3"
        $Settings = Get-ItemPropertyValue -Path $StuckPath -Name "Settings" -ErrorAction Stop
        return $Settings[8] -eq 3
    } catch {
        return $false
    }
}

function Get-HideIconsStatus {
    try {
        $AdvancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        $Val = Get-ItemPropertyValue -Path $AdvancedPath -Name "HideIcons" -ErrorAction Stop
        return $Val -eq 1
    } catch {
        return $false
    }
}

function Get-DateTimeStatus {
    try {
        $Path = "HKCU:\Control Panel\International"
        $ShortDate = Get-ItemPropertyValue -Path $Path -Name "sShortDate" -ErrorAction Stop
        $ShortTime = Get-ItemPropertyValue -Path $Path -Name "sShortTime" -ErrorAction Stop
        if ($ShortDate -eq "dd-MM-yyyy" -and ($ShortTime -eq "HH:mm" -or $ShortTime -eq "H:mm")) {
            return $true
        }
        return $false
    } catch {
        return $false
    }
}

function Update-DateTimeFormats {
    param(
        [string]$ShortDate,
        [string]$ShortTime,
        [string]$TimeFormat
    )

    $Path = "HKCU:\Control Panel\International"
    Set-ItemProperty -Path $Path -Name "sShortDate" -Value $ShortDate -Force
    Set-ItemProperty -Path $Path -Name "sShortTime" -Value $ShortTime -Force
    Set-ItemProperty -Path $Path -Name "sTimeFormat" -Value $TimeFormat -Force

    # Broadcast WM_SETTINGCHANGE to update taskbar clock instantly
    try {
        $Type = $null
        try {
            $Type = [Win32.Win32Utils]
        } catch {
            $Signature = @'
            [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
            public static extern IntPtr SendMessageTimeout(
                IntPtr hWnd,
                uint Msg,
                IntPtr wParam,
                string lParam,
                uint fuFlags,
                uint uTimeout,
                out IntPtr lpdwResult
            );
'@
            Add-Type -MemberDefinition $Signature -Name "Win32Utils" -Namespace "Win32" -ErrorAction Stop | Out-Null
            $Type = [Win32.Win32Utils]
        }

        if ($Type) {
            $Result = [IntPtr]::Zero
            # hWnd = HWND_BROADCAST (0xffff), Msg = WM_SETTINGCHANGE (0x001a), wParam = 0, lParam = "intl"
            # Flags: SMTO_ABORTIFHUNG (2), Timeout: 5000ms
            $Type::SendMessageTimeout([IntPtr]0xffff, 0x001a, [IntPtr]::Zero, "intl", 2, 5000, [ref]$Result) | Out-Null
        }
    } catch {
        Write-Host "Warning: Could not broadcast format update. Log off or restart Windows Explorer to apply changes." -ForegroundColor Yellow
    }
}

# --- 1. Taskbar only on primary monitor ---
$MMTaskbarActive = Get-MMTaskbarStatus
if ($MMTaskbarActive) {
    $Question = "Taskbar is currently set to primary screen only. Do you want to RESTORE the taskbar to all screens?"
} else {
    $Question = "Do you want to show the taskbar ONLY on the primary screen (disable multi-monitor taskbars)?"
}
if (Request-Confirmation $Question) {
    try {
        $AdvancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        $NewVal = if ($MMTaskbarActive) { 1 } else { 0 }
        $Msg = if ($MMTaskbarActive) { "Restoring taskbar to all screens..." } else { "Configuring taskbar to show only on primary monitor..." }
        Write-Log $Msg
        Set-ItemProperty -Path $AdvancedPath -Name "MMTaskbarEnabled" -Value $NewVal -Type DWord -Force
        $NeedExplorerRestart = $true
    } catch {
        Write-Host "  [ERROR] Failed to configure multimonitor taskbar setting: $_" -ForegroundColor Red
    }
}

# --- 2. Auto-hide Taskbar ---
$AutoHideActive = Get-AutoHideStatus
if ($AutoHideActive) {
    $Question = "Taskbar Auto-Hide is currently enabled. Do you want to DISABLE taskbar Auto-Hide?"
} else {
    $Question = "Do you want to ENABLE taskbar Auto-Hide?"
}
if (Request-Confirmation $Question) {
    $StuckPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3"
    try {
        $Settings = Get-ItemPropertyValue -Path $StuckPath -Name "Settings" -ErrorAction Stop
        $NewByte = if ($AutoHideActive) { 2 } else { 3 }
        $Msg = if ($AutoHideActive) { "Disabling taskbar Auto-Hide..." } else { "Enabling taskbar Auto-Hide..." }
        Write-Log $Msg
        $Settings[8] = $NewByte
        Set-ItemProperty -Path $StuckPath -Name "Settings" -Value $Settings -Force
        $NeedExplorerRestart = $true
    } catch {
        Write-Host "  [ERROR] Failed to modify taskbar auto-hide registry settings: $_" -ForegroundColor Red
    }
}

# --- 3. Hide Desktop Icons ---
$HideIconsActive = Get-HideIconsStatus
if ($HideIconsActive) {
    $Question = "Desktop icons are currently hidden. Do you want to SHOW desktop icons?"
} else {
    $Question = "Do you want to HIDE all desktop icons?"
}
if (Request-Confirmation $Question) {
    try {
        $AdvancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        $NewVal = if ($HideIconsActive) { 0 } else { 1 }
        $Msg = if ($HideIconsActive) { "Showing desktop icons..." } else { "Hiding desktop icons..." }
        Write-Log $Msg
        Set-ItemProperty -Path $AdvancedPath -Name "HideIcons" -Value $NewVal -Type DWord -Force
        $NeedExplorerRestart = $true
    } catch {
        Write-Host "  [ERROR] Failed to modify desktop icons visibility: $_" -ForegroundColor Red
    }
}

# --- 4. Date and Time Format ---
$DateTimeActive = Get-DateTimeStatus
if ($DateTimeActive) {
    $Question = "Date format is dd-MM-yyyy and 24-hour. Do you want to REVERT to default (M/d/yyyy and 12-hour)?"
} else {
    $Question = "Do you want to set the short date format to dd-MM-yyyy and the time to 24-hour format?"
}
if (Request-Confirmation $Question) {
    try {
        if ($DateTimeActive) {
            Write-Log "Reverting short date to default M/d/yyyy and time to 12H..."
            Update-DateTimeFormats -ShortDate "M/d/yyyy" -ShortTime "h:mm tt" -TimeFormat "h:mm:ss tt"
        } else {
            Write-Log "Setting short date to dd-MM-yyyy and time to 24H..."
            Update-DateTimeFormats -ShortDate "dd-MM-yyyy" -ShortTime "HH:mm" -TimeFormat "HH:mm:ss"
        }
        Write-Log "Date and time formats updated successfully."
    } catch {
        Write-Host "  [ERROR] Failed to update date and time formats: $_" -ForegroundColor Red
    }
}

# --- 5. PowerShell Script Execution Policy ---
$CurrentPolicy = Get-ExecutionPolicy -Scope CurrentUser
$MachinePolicy = Get-ExecutionPolicy -Scope LocalMachine
$PolicyActive = ($CurrentPolicy -in @("RemoteSigned", "Unrestricted", "Bypass")) -or ($MachinePolicy -in @("RemoteSigned", "Unrestricted", "Bypass"))

if ($PolicyActive) {
    $Question = "PowerShell script execution is currently enabled ($CurrentPolicy). Do you want to RESTRICT it to default (Undefined)?"
} else {
    $Question = "Do you want to PERMANENTLY allow executing local PowerShell scripts (Set ExecutionPolicy to RemoteSigned)?"
}
if (Request-Confirmation $Question) {
    try {
        if ($PolicyActive) {
            Write-Log "Restricting PowerShell execution policy to default..."
            Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope CurrentUser -Force
            Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope LocalMachine -Force
        } else {
            Write-Log "Setting PowerShell execution policy to RemoteSigned..."
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force
        }
        Write-Log "PowerShell execution policy updated successfully."
    } catch {
        Write-Host "  [ERROR] Failed to update execution policy: $_" -ForegroundColor Red
    }
}

# --- 6. Restart Windows Explorer to apply changes ---
if ($NeedExplorerRestart) {
    Write-Log "Restarting Windows Explorer to apply changes..."
    try {
        Stop-Process -Name explorer -Force
        Write-Log "Windows Explorer restarted successfully."
    } catch {
        Write-Host "  [WARN] Failed to restart Windows Explorer. Please restart it manually or log out to apply changes." -ForegroundColor Yellow
    }
} else {
    Write-Log "No taskbar/desktop tweaks were applied. Skipping Windows Explorer restart."
}
