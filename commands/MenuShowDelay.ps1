param(
    [switch]$GetInfo,
    [switch]$Status,
    [switch]$Enable,
    [switch]$Disable
)

# Metadata definitions
$Name = "Menu Show Delay"
$Description = "Sets the delay (in milliseconds) before Windows displays context and drop-down menus."

$WhyEnable = @(
    "Faster Menus: Reduces the delay to 20ms (down from the default 400ms), making the desktop UI and context menus appear almost instantly."
)

$WhyDisable = @(
    "Default Delay: Restores the default 400ms delay, preventing menus from accidentally popping open immediately when hovering."
)

function Get-CurrentStatus {
    try {
        $Path = "HKCU:\Control Panel\Desktop"
        $Value = Get-ItemPropertyValue -Path $Path -Name "MenuShowDelay" -ErrorAction Stop
        if ($Value -eq "20") {
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
    Write-Host "Reducing MenuShowDelay to 20ms..." -ForegroundColor Cyan
    try {
        $Path = "HKCU:\Control Panel\Desktop"
        Set-ItemProperty -Path $Path -Name "MenuShowDelay" -Value "20" -Force
        
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
        
        Write-Host "MenuShowDelay updated successfully." -ForegroundColor Green
    } catch {
        Write-Error "Failed to update MenuShowDelay: $_"
        exit 1
    }
    exit
}

if ($Disable) {
    Write-Host "Restoring default MenuShowDelay to 400ms..." -ForegroundColor Cyan
    try {
        $Path = "HKCU:\Control Panel\Desktop"
        Set-ItemProperty -Path $Path -Name "MenuShowDelay" -Value "400" -Force
        
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
        
        Write-Host "MenuShowDelay restored to default successfully." -ForegroundColor Green
    } catch {
        Write-Error "Failed to restore MenuShowDelay: $_"
        exit 1
    }
    exit
}
