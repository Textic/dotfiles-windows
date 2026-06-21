param(
    [switch]$GetInfo,
    [switch]$Status,
    [switch]$Enable,
    [switch]$Disable
)

# Metadata definitions
$Name = "Desktop & Process Response Time"
$Description = "Forces Windows to automatically close hung applications and drastically reduces UI delays and menu show times."

$WhyEnable = @(
    "Auto Close: Enables AutoEndTasks (1) to automatically close hung applications on shutdown.",
    "Hung App Timeout: Reduces HungAppTimeout to 1000ms (1 second) to detect frozen apps faster.",
    "App Kill Timeout: Reduces WaitToKillAppTimeout to 2000ms (2 seconds) to force termination of hanging apps faster.",
    "Hooks Delay: Reduces LowLevelHooksTimeout to 1000ms (1 second) to prevent input delay when apps are busy.",
    "Instant Menus: Reduces MenuShowDelay to 10ms for near-instant rendering of context and drop-down menus.",
    "Hover Preview: Reduces ExtendedUIHoverTime to 10ms for near-instant rendering of taskbar thumbnail previews."
)

$WhyDisable = @(
    "Default Response: Restores standard Windows settings (400ms menu delay, 5s hung detection, and removes forced closure limits)."
)

function Get-CurrentStatus {
    try {
        $Path = "HKCU:\Control Panel\Desktop"
        $AutoEnd = Get-ItemPropertyValue -Path $Path -Name "AutoEndTasks" -ErrorAction SilentlyContinue
        $HungTimeout = Get-ItemPropertyValue -Path $Path -Name "HungAppTimeout" -ErrorAction SilentlyContinue
        $WaitTimeout = Get-ItemPropertyValue -Path $Path -Name "WaitToKillAppTimeout" -ErrorAction SilentlyContinue
        $HooksTimeout = Get-ItemPropertyValue -Path $Path -Name "LowLevelHooksTimeout" -ErrorAction SilentlyContinue
        $MenuDelay = Get-ItemPropertyValue -Path $Path -Name "MenuShowDelay" -ErrorAction SilentlyContinue

        $AdvancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        $HoverTime = Get-ItemPropertyValue -Path $AdvancedPath -Name "ExtendedUIHoverTime" -ErrorAction SilentlyContinue

        if ($AutoEnd -eq "1" -and $HungTimeout -eq "1000" -and $WaitTimeout -eq "2000" -and $HooksTimeout -eq "1000" -and $MenuDelay -eq "10" -and $HoverTime -eq 10) {
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
    Write-Host "Optimizing desktop and process response times..." -ForegroundColor Cyan
    try {
        $Path = "HKCU:\Control Panel\Desktop"
        Set-ItemProperty -Path $Path -Name "AutoEndTasks" -Value "1" -Type String -Force
        Set-ItemProperty -Path $Path -Name "HungAppTimeout" -Value "1000" -Type String -Force
        Set-ItemProperty -Path $Path -Name "WaitToKillAppTimeout" -Value "2000" -Type String -Force
        Set-ItemProperty -Path $Path -Name "LowLevelHooksTimeout" -Value "1000" -Type String -Force
        Set-ItemProperty -Path $Path -Name "MenuShowDelay" -Value "10" -Type String -Force

        $AdvancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Set-ItemProperty -Path $AdvancedPath -Name "ExtendedUIHoverTime" -Value 10 -Type DWord -Force

        # Broadcast settings change to apply instantly
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
                $Type::SendMessageTimeout([IntPtr]0xffff, 0x001a, [IntPtr]::Zero, "intl", 2, 5000, [ref]$Result) | Out-Null
            }
        } catch {}

        Write-Host "Desktop and process response times optimized successfully." -ForegroundColor Green
    } catch {
        Write-Error "Failed to optimize desktop response times: $_"
        exit 1
    }
    exit
}

if ($Disable) {
    Write-Host "Restoring default desktop and process response times..." -ForegroundColor Cyan
    try {
        $Path = "HKCU:\Control Panel\Desktop"
        Set-ItemProperty -Path $Path -Name "MenuShowDelay" -Value "400" -Type String -Force
        
        Remove-ItemProperty -Path $Path -Name "AutoEndTasks" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $Path -Name "HungAppTimeout" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $Path -Name "WaitToKillAppTimeout" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $Path -Name "LowLevelHooksTimeout" -ErrorAction SilentlyContinue

        $AdvancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Remove-ItemProperty -Path $AdvancedPath -Name "ExtendedUIHoverTime" -ErrorAction SilentlyContinue

        # Broadcast settings change to apply instantly
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
                $Type::SendMessageTimeout([IntPtr]0xffff, 0x001a, [IntPtr]::Zero, "intl", 2, 5000, [ref]$Result) | Out-Null
            }
        } catch {}

        Write-Host "Desktop and process response times restored to default successfully." -ForegroundColor Green
    } catch {
        Write-Error "Failed to restore desktop response times: $_"
        exit 1
    }
    exit
}
