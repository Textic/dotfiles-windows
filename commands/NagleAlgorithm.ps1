param(
    [switch]$GetInfo,
    [switch]$Status,
    [switch]$Enable,
    [switch]$Disable
)

# Metadata definitions
$Name = "Nagle's Algorithm (TCP No Delay)"
$Description = "Disables Nagle's Algorithm to improve network responsiveness and reduce ping/latency in online games."

$WhyEnable = @(
    "Disable Nagling: Sets TCPNoDelay to 1 to force packets to be sent immediately instead of holding them to bundle into larger packets.",
    "Fast ACKs: Sets TcpAckFrequency to 1 and TcpDelAckTicks to 0 to disable TCP acknowledgment delays, reducing ping spikes in online games."
)

$WhyDisable = @(
    "Default TCP: Removes the custom TCP parameters, restoring Windows default behavior (Nagle's Algorithm enabled) for standard network throughput efficiency."
)

function Get-CurrentStatus {
    try {
        $Adapters = Get-NetAdapter -ErrorAction SilentlyContinue
        if (-not $Adapters) { return $false }
        
        $TotalCount = 0
        $EnabledCount = 0
        
        foreach ($Adapter in $Adapters) {
            $Guid = $Adapter.InterfaceGUID
            $Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$Guid"
            if (Test-Path $Path) {
                $TotalCount++
                $TcpAckFrequency = Get-ItemPropertyValue -Path $Path -Name "TcpAckFrequency" -ErrorAction SilentlyContinue
                $TCPNoDelay = Get-ItemPropertyValue -Path $Path -Name "TCPNoDelay" -ErrorAction SilentlyContinue
                $TcpDelAckTicks = Get-ItemPropertyValue -Path $Path -Name "TcpDelAckTicks" -ErrorAction SilentlyContinue
                
                if ($TcpAckFrequency -eq 1 -and $TCPNoDelay -eq 1 -and $TcpDelAckTicks -eq 0) {
                    $EnabledCount++
                }
            }
        }
        
        if ($TotalCount -gt 0 -and $EnabledCount -eq $TotalCount) {
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
    Write-Host "Disabling Nagle's Algorithm on all network adapters..." -ForegroundColor Cyan
    try {
        $Adapters = Get-NetAdapter -ErrorAction SilentlyContinue
        if (-not $Adapters) {
            Write-Error "No network adapters found to configure."
            exit 1
        }
        
        foreach ($Adapter in $Adapters) {
            $Guid = $Adapter.InterfaceGUID
            $Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$Guid"
            if (Test-Path $Path) {
                Set-ItemProperty -Path $Path -Name "TcpAckFrequency" -Value 1 -Type DWord -Force
                Set-ItemProperty -Path $Path -Name "TCPNoDelay" -Value 1 -Type DWord -Force
                Set-ItemProperty -Path $Path -Name "TcpDelAckTicks" -Value 0 -Type DWord -Force
                Write-Host "  Optimized adapter: $($Adapter.Name) ($Guid)" -ForegroundColor Gray
            }
        }
        Write-Host "Nagle's Algorithm disabled successfully." -ForegroundColor Green
    } catch {
        Write-Error "Failed to disable Nagle's Algorithm: $_"
        exit 1
    }
    exit
}

if ($Disable) {
    Write-Host "Restoring default TCP settings (enabling Nagle's Algorithm)..." -ForegroundColor Cyan
    try {
        $Adapters = Get-NetAdapter -ErrorAction SilentlyContinue
        foreach ($Adapter in $Adapters) {
            $Guid = $Adapter.InterfaceGUID
            $Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$Guid"
            if (Test-Path $Path) {
                Remove-ItemProperty -Path $Path -Name "TcpAckFrequency" -ErrorAction SilentlyContinue
                Remove-ItemProperty -Path $Path -Name "TCPNoDelay" -ErrorAction SilentlyContinue
                Remove-ItemProperty -Path $Path -Name "TcpDelAckTicks" -ErrorAction SilentlyContinue
                Write-Host "  Restored adapter: $($Adapter.Name) ($Guid)" -ForegroundColor Gray
            }
        }
        Write-Host "TCP settings restored to default successfully." -ForegroundColor Green
    } catch {
        Write-Error "Failed to restore TCP settings: $_"
        exit 1
    }
    exit
}
