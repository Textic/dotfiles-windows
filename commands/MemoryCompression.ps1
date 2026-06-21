param(
    [switch]$GetInfo,
    [switch]$Status,
    [switch]$Enable,
    [switch]$Disable
)

# Metadata definitions
$Name = "Memory Compression (MMAgent)"
$Description = "Manages Windows virtual memory compression to save RAM or free up CPU."

$WhyEnable = @(
    "You have 8 GB or 16 GB of RAM: At this capacity, compression is vital. If disabled, Windows will quickly deplete physical RAM and fall back to the hard drive (Pagefile), heavily slowing down the PC as soon as you open multiple browser tabs or a heavy game.",
    "You use a Laptop and prioritize battery life: Although the CPU works slightly harder during compression, it prevents the hard drive from active read/write virtualization cycles, which generally saves more battery power.",
    "General PC usage: If you play casually, do office work, program, or watch media, Windows memory compression is highly efficient and you won't even notice it running."
)

$WhyDisable = @(
    "You have plenty of RAM (32 GB or more): With excess RAM, you don't need Windows wasting CPU cycles compressing memory to save space.",
    "You seek to squeeze every millisecond in Competitive Gaming: Data compression and decompression consumes CPU cycles. Disabling it can eliminate micro-stuttering or millisecond frametime drops in demanding games.",
    "You work with Professional Audio (DAWs): In real-time music production, any background CPU process causing latency is an enemy.",
    "Your CPU is old or low-end but you have good RAM: If your processor struggles with daily tasks, removing the burden of memory compression will give it breathing room."
)

function Get-CurrentStatus {
    try {
        $Agent = Get-MMAgent -ErrorAction Stop
        return $Agent.MemoryCompression
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
    Write-Host "Enabling memory compression (Enable-MMAgent -MemoryCompression)..." -ForegroundColor Cyan
    try {
        Enable-MMAgent -MemoryCompression -ErrorAction Stop
        Write-Host "Memory compression enabled successfully." -ForegroundColor Green
    } catch {
        Write-Error "Error enabling memory compression: $_"
        exit 1
    }
    exit
}

if ($Disable) {
    Write-Host "Disabling memory compression (Disable-MMAgent -MemoryCompression)..." -ForegroundColor Cyan
    try {
        Disable-MMAgent -MemoryCompression -ErrorAction Stop
        Write-Host "Memory compression disabled successfully." -ForegroundColor Green
    } catch {
        Write-Error "Error disabling memory compression: $_"
        exit 1
    }
    exit
}
