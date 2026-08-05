# File: scripts/05_tweaks.ps1
# Description: Sequential wizard to manage individual commands and system tweaks.
# Equips dotfiles with a step-by-step interactive optimizer using repository standards.

# Ensure utilities and administrator privileges
$ScriptRoot = $PSScriptRoot
if (-not (Get-Command "Write-Log" -ErrorAction SilentlyContinue)) {
    if (Test-Path "$ScriptRoot\00_utils.ps1") {
        . "$ScriptRoot\00_utils.ps1"
    }
}
if (Get-Command "Ensure-Admin" -ErrorAction SilentlyContinue) { Ensure-Admin }

$CommandsDir = Resolve-Path "$ScriptRoot\..\commands" -ErrorAction SilentlyContinue
if (-not $CommandsDir) {
    $CommandsDir = "$ScriptRoot\..\commands"
}

if (-not (Test-Path $CommandsDir)) {
    Write-Log "Commands directory not found. Creating it..."
    New-Item -ItemType Directory -Path $CommandsDir -Force | Out-Null
}

function Invoke-TweaksWizard {
    # Scan for commands
    $TweakFiles = Get-ChildItem -Path $CommandsDir -Filter "*.ps1"
    if ($TweakFiles.Count -eq 0) {
        return
    }

    # Load tweaks dynamically
    $TweaksList = @()
    foreach ($File in $TweakFiles) {
        try {
            $Info = & $File.FullName -GetInfo -ErrorAction Stop
            if ($Info -and $Info.Name) {
                $TweaksList += [PSCustomObject]@{
                    FilePath      = $File.FullName
                    Name          = $Info.Name
                    Description   = $Info.Description
                    WhyEnable     = $Info.WhyEnable
                    WhyDisable    = $Info.WhyDisable
                    Status        = $Info.Status
                    ShowStatus    = $Info.ShowStatus
                }
            }
        } catch {
            Write-Host "  [!] Error loading tweak from $($File.Name): $_" -ForegroundColor Red
        }
    }

    $Count = $TweaksList.Count
    Write-Log "Starting individual tweaks module ($Count tweaks available)..."
    Write-Host ""

    for ($i = 0; $i -lt $Count; $i++) {
        $Tweak = $TweaksList[$i]
        $Step = $i + 1
        $HasStatus = $Tweak.ShowStatus -eq $true

        if ($Global:Unattended) {
            Write-Host "--- Tweak ($Step/$Count): $($Tweak.Name) ---" -ForegroundColor Cyan
            if ($HasStatus) {
                if ($Tweak.Status) {
                    Write-Host "Current Status: [ACTIVE] -> Skipping." -ForegroundColor Green
                } else {
                    Write-Host "Current Status: [INACTIVE] -> Auto-enabling." -ForegroundColor Yellow
                    & $Tweak.FilePath -Enable
                }
            } else {
                Write-Host "Auto-applying settings..." -ForegroundColor Yellow
                & $Tweak.FilePath -Enable
            }
            Write-Host ""
            Start-Sleep -Seconds 1
            continue
        }

        # Print Tweak Header
        Write-Host "--- Tweak ($Step/$Count): $($Tweak.Name) ---" -ForegroundColor Cyan
        Write-Host "Description: $($Tweak.Description)" -ForegroundColor White

        # Status
        if ($HasStatus) {
            $StatusStr = "INACTIVE"
            $StatusColor = "Yellow"
            if ($Tweak.Status) {
                $StatusStr = "ACTIVE"
                $StatusColor = "Green"
            }
            Write-Host "Current Status: " -NoNewline -ForegroundColor DarkGray
            Write-Host "[$StatusStr]" -ForegroundColor $StatusColor
        }
        Write-Host ""

        # Why Enable
        Write-Host "[+] WHEN YOU SHOULD ENABLE IT:" -ForegroundColor Green
        foreach ($Point in $Tweak.WhyEnable) {
            if ($Point -like "*:*") {
                $Parts = $Point -split ":", 2
                Write-Host "  * " -NoNewline -ForegroundColor Green
                Write-Host ($Parts[0] + ":") -NoNewline -ForegroundColor White
                Write-Host $Parts[1] -ForegroundColor Gray
            } else {
                Write-Host "  * $Point" -ForegroundColor Gray
            }
        }
        Write-Host ""

        # Why Disable
        Write-Host "[-] WHEN YOU SHOULD DISABLE IT:" -ForegroundColor Red
        foreach ($Point in $Tweak.WhyDisable) {
            if ($Point -like "*:*") {
                $Parts = $Point -split ":", 2
                Write-Host "  * " -NoNewline -ForegroundColor Red
                Write-Host ($Parts[0] + ":") -NoNewline -ForegroundColor White
                Write-Host $Parts[1] -ForegroundColor Gray
            } else {
                Write-Host "  * $Point" -ForegroundColor Gray
            }
        }
        Write-Host ""

        # Formulate confirmation question based on ShowStatus and Current Status
        $ActionToRun = "Enable"
        if ($HasStatus) {
            if ($Tweak.Status) {
                $Question = "Do you want to DISABLE '$($Tweak.Name)'?"
                $ActionToRun = "Disable"
            } else {
                $Question = "Do you want to ENABLE '$($Tweak.Name)'?"
                $ActionToRun = "Enable"
            }
        } else {
            $Question = "Do you want to apply the '$($Tweak.Name)' settings?"
            $ActionToRun = "Enable"
        }

        # Ask user using standard Request-Confirmation from 00_utils.ps1
        if (Request-Confirmation $Question) {
            Write-Host ""
            if ($ActionToRun -eq "Disable") {
                & $Tweak.FilePath -Disable
            } else {
                & $Tweak.FilePath -Enable
            }
            Start-Sleep -Seconds 2
        } else {
            Write-Log "Skipping tweak '$($Tweak.Name)'."
            Start-Sleep -Seconds 1
        }
        Write-Host ""
    }

    Write-Log "All individual tweaks configuration finished."
}

# Run the sequential wizard!
Invoke-TweaksWizard
