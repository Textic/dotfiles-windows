param(
    [switch]$GetInfo,
    [switch]$Status,
    [switch]$Enable,
    [switch]$Disable
)

# Metadata definitions
$Name = "Date and Time Format"
$Description = "Sets Windows short date format to dd-MM-yyyy and time to 24-hour clock."

$WhyEnable = @(
    "Short Date: Sets Windows short date format to dd-MM-yyyy (e.g. 15-06-2026).",
    "24H Clock: Sets short time format to HH:mm (e.g. 19:01) and long time format to HH:mm:ss.",
    "Immediate Update: Broadcasts the change to apply format adjustments to the taskbar clock instantly without logging out."
)

$WhyDisable = @(
    "US Standard: Reverts short date format to default M/d/yyyy (e.g. 6/15/2026).",
    "12H Clock: Reverts time formats to 12-hour format with AM/PM indicators (h:mm tt and h:mm:ss tt)."
)

function Get-CurrentStatus {
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

if ($GetInfo) {
    [PSCustomObject]@{
        Name          = $Name
        Description   = $Description
        WhyEnable     = $WhyEnable
        WhyDisable    = $WhyDisable
        Status        = (Get-CurrentStatus)
    }
    exit
}

if ($Status) {
    return (Get-CurrentStatus)
}

if ($Enable) {
    Write-Host "Setting short date to dd-MM-yyyy and time to 24H..." -ForegroundColor Cyan
    try {
        Update-DateTimeFormats -ShortDate "dd-MM-yyyy" -ShortTime "HH:mm" -TimeFormat "HH:mm:ss"
        Write-Host "Date and time formats updated successfully." -ForegroundColor Green
    } catch {
        Write-Error "Failed to update date and time formats: $_"
        exit 1
    }
    exit
}

if ($Disable) {
    Write-Host "Reverting short date to default M/d/yyyy and time to 12H..." -ForegroundColor Cyan
    try {
        Update-DateTimeFormats -ShortDate "M/d/yyyy" -ShortTime "h:mm tt" -TimeFormat "h:mm:ss tt"
        Write-Host "Date and time formats reverted successfully." -ForegroundColor Green
    } catch {
        Write-Error "Failed to revert date and time formats: $_"
        exit 1
    }
    exit
}
