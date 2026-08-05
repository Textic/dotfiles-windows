# Ensure utilities and administrator privileges
$ScriptRoot = $PSScriptRoot
if (-not (Get-Command "Write-Log" -ErrorAction SilentlyContinue)) {
    if (Test-Path "$ScriptRoot\00_utils.ps1") {
        . "$ScriptRoot\00_utils.ps1"
    }
}
if (Get-Command "Ensure-Admin" -ErrorAction SilentlyContinue) { Ensure-Admin }

$ErrorActionPreference = "Stop"

Write-Host "Starting Font Installation..." -ForegroundColor Cyan

if (Request-Confirmation "Do you want to install custom fonts?") {
    $FontsSource = Resolve-Path "$PSScriptRoot\..\fonts" -ErrorAction SilentlyContinue
    if (-not $FontsSource -or -not (Test-Path $FontsSource)) {
        Write-Host "[ERROR] Fonts directory not found." -ForegroundColor Red
        return
    }

    $WindowsFontsDir = "C:\Windows\Fonts"
    $RegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"

    $FontFiles = Get-ChildItem -Path $FontsSource -Include "*.ttf", "*.otf" -Recurse

    if ($FontFiles.Count -eq 0) {
        Write-Host "[INFO] No font files found to install." -ForegroundColor Yellow
        return
    }

    foreach ($FontFile in $FontFiles) {
        $FontName = $FontFile.Name
        
        # Check if font is already in the Windows Fonts folder
        if (-not (Test-Path "$WindowsFontsDir\$FontName")) {
            try {
                Write-Host "[INSTALL] Installing $FontName..." -ForegroundColor Green
                
                # 1. Copy the font file to the Windows Fonts directory
                Copy-Item -Path $FontFile.FullName -Destination $WindowsFontsDir -Force
                
                # 2. Register the font in the Registry
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
} else {
    Write-Log "Skipping fonts."
}