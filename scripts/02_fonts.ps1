$ErrorActionPreference = "Stop"

$ScriptRoot = $PSScriptRoot
$FontsSource = Resolve-Path "$ScriptRoot\..\fonts"

Write-Host "Starting Font Installation..." -ForegroundColor Cyan

if (-not (Test-Path $FontsSource)) {
    Write-Host "[ERROR] Fonts directory not found at: $FontsSource" -ForegroundColor Red
    exit
}

$WindowsFontsDir = "C:\Windows\Fonts"
$RegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"

$FontFiles = Get-ChildItem -Path $FontsSource -Include "*.ttf", "*.otf" -Recurse

if ($FontFiles.Count -eq 0) {
    Write-Host "[INFO] No font files found to install." -ForegroundColor Yellow
    exit
}

foreach ($FontFile in $FontFiles) {
    $FontName = $FontFile.Name
    
    # Check if font is already in the Windows Fonts folder
    if (-not (Test-Path "$WindowsFontsDir\$FontName")) {
        try {
            Write-Host "[INSTALL] Installing $FontName..." -ForegroundColor Green
            
            # 1. Copy the font file to the Windows Fonts directory
            Copy-Item -Path $FontFile.FullName -Destination $WindowsFontsDir -Force
            
            # 2. Register the font in the Registry (Required for Windows to recognize it)
            # We use the file name as the value unless it's a specific type like "TrueType"
            $RegValue = $FontName
            if ($FontFile.Extension -eq ".ttf") { $RegValue = "$FontName (TrueType)" }
            
            New-ItemProperty -Path $RegistryPath -Name $RegValue -Value $FontName -PropertyType String -Force | Out-Null
        }
        catch {
            Write-Host "[ERROR] Failed to install $FontName. $_" -ForegroundColor Red
        }
    }
    else {
        Write-Host "[SKIP] $FontName is already installed." -ForegroundColor DarkGray
    }
}

Write-Host "Font installation complete." -ForegroundColor Green