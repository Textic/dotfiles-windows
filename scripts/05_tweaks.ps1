# File: scripts/05_tweaks.ps1
# Description: Dynamic CLI menu to display and manage individual commands and system tweaks.
# Equips dotfiles with a customizable, interactive optimizer.

# Ensure utilities are imported (if run standalone)
$ScriptRoot = $PSScriptRoot
if (-not (Get-Command "Write-Log" -ErrorAction SilentlyContinue)) {
    if (Test-Path "$ScriptRoot\00_utils.ps1") {
        . "$ScriptRoot\00_utils.ps1"
    } else {
        function Write-Log { param($Message) Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] $Message" -ForegroundColor Yellow }
    }
}

function Test-IsAdmin {
    $Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object Security.Principal.WindowsPrincipal($Identity)
    return $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

$CommandsDir = Resolve-Path "$ScriptRoot\..\commands" -ErrorAction SilentlyContinue
if (-not $CommandsDir) {
    $CommandsDir = "$ScriptRoot\..\commands"
}

if (-not (Test-Path $CommandsDir)) {
    Write-Log "No se encontro la carpeta 'commands'. Creandola..."
    New-Item -ItemType Directory -Path $CommandsDir -Force | Out-Null
}

function Show-Header {
    Clear-Host
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "     SISTEMA DE COMANDOS Y OPTIMIZACIONES INDIVIDUALES    " -ForegroundColor Green
    Write-Host "==========================================================" -ForegroundColor Cyan
    if (Test-IsAdmin) {
        Write-Host " [ELEVADO] Ejecutando como Administrador (Listo para aplicar tweaks)" -ForegroundColor Green
    } else {
        Write-Host " [SOLO LECTURA] Ejecutando sin privilegios de Administrador" -ForegroundColor Yellow
        Write-Host "   * Nota: Algunos tweaks requeriran reiniciar este script como Admin para ser modificados." -ForegroundColor DarkGray
    }
    Write-Host ""
}

function Run-TweaksMenu {
    $ExitMenu = $false
    while (-not $ExitMenu) {
        Show-Header
        
        # Scan for commands
        $TweakFiles = Get-ChildItem -Path $CommandsDir -Filter "*.ps1"
        if ($TweakFiles.Count -eq 0) {
            Write-Host "No se encontraron comandos o tweaks individuales en: $CommandsDir" -ForegroundColor Yellow
            Write-Host "Puedes agregar scripts .ps1 a esta carpeta para extender las opciones del sistema." -ForegroundColor DarkGray
            Write-Host ""
            Read-Host "Presiona Enter para salir..."
            break
        }

        # Load tweaks dynamically
        $TweaksList = @()
        Write-Host "Cargando optimizaciones y comandos disponibles..." -ForegroundColor Gray
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
                        RequiresAdmin = $Info.RequiresAdmin
                    }
                }
            } catch {
                Write-Host "  [!] Error al cargar tweak desde $($File.Name): $_" -ForegroundColor Red
            }
        }

        Show-Header
        Write-Host "Optimizaciones disponibles:" -ForegroundColor White
        Write-Host "----------------------------------------------------------" -ForegroundColor DarkGray

        for ($i = 0; $i -lt $TweaksList.Count; $i++) {
            $Tweak = $TweaksList[$i]
            $Num = $i + 1
            $StatusStr = "INACTIVO"
            $StatusColor = "Yellow"
            if ($Tweak.Status) {
                $StatusStr = "ACTIVO"
                $StatusColor = "Green"
            }
            
            Write-Host "  [$Num] " -NoNewline -ForegroundColor Cyan
            Write-Host "$($Tweak.Name)" -NoNewline -ForegroundColor White
            Write-Host " - Estado: " -NoNewline -ForegroundColor DarkGray
            Write-Host "[$StatusStr]" -ForegroundColor $StatusColor
            Write-Host "      $($Tweak.Description)" -ForegroundColor Gray
            Write-Host ""
        }

        Write-Host "----------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host " [Q] Salir del menu" -ForegroundColor Cyan
        Write-Host ""
        
        $Selection = Read-Host "Elige una opcion"
        if ($Selection -match "^(q|Q)$") {
            $ExitMenu = $true
            continue
        }

        if ($Selection -match "^\d+$") {
            $Idx = [int]$Selection - 1
            if ($Idx -ge 0 -and $Idx -lt $TweaksList.Count) {
                Show-TweakDetails $TweaksList[$Idx]
            } else {
                Write-Host "Opcion invalida. Intentalo de nuevo." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        } else {
            Write-Host "Opcion invalida. Intentalo de nuevo." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}

function Show-TweakDetails {
    param(
        [Parameter(Mandatory=$true)]
        $Tweak
    )

    $BackToMenu = $false
    while (-not $BackToMenu) {
        Clear-Host
        Write-Host "==========================================================" -ForegroundColor Cyan
        Write-Host "  DETALLE DE OPTIMIZACION: $($Tweak.Name)" -ForegroundColor Green
        Write-Host "==========================================================" -ForegroundColor Cyan
        Write-Host "Descripcion: " -NoNewline -ForegroundColor DarkGray
        Write-Host $Tweak.Description -ForegroundColor White
        Write-Host ""

        # Status
        $StatusStr = "INACTIVO"
        $StatusColor = "Yellow"
        if ($Tweak.Status) {
            $StatusStr = "ACTIVO"
            $StatusColor = "Green"
        }
        Write-Host "Estado Actual: " -NoNewline -ForegroundColor DarkGray
        Write-Host "[$StatusStr]" -ForegroundColor $StatusColor
        Write-Host ""

        # Why Enable
        Write-Host "[+] CUANDO DEBERIAS ACTIVARLO" -ForegroundColor Green
        Write-Host "----------------------------------------------------------" -ForegroundColor DarkGray
        foreach ($Point in $Tweak.WhyEnable) {
            if ($Point -like "*:*") {
                $Parts = $Point -split ":", 2
                Write-Host "  o " -NoNewline -ForegroundColor Green
                Write-Host ($Parts[0] + ":") -NoNewline -ForegroundColor White
                Write-Host $Parts[1] -ForegroundColor Gray
            } else {
                Write-Host "  o $Point" -ForegroundColor Gray
            }
        }
        Write-Host ""

        # Why Disable
        Write-Host "[-] CUANDO DEBERIAS DESACTIVARLO" -ForegroundColor Red
        Write-Host "----------------------------------------------------------" -ForegroundColor DarkGray
        foreach ($Point in $Tweak.WhyDisable) {
            if ($Point -like "*:*") {
                $Parts = $Point -split ":", 2
                Write-Host "  o " -NoNewline -ForegroundColor Red
                Write-Host ($Parts[0] + ":") -NoNewline -ForegroundColor White
                Write-Host $Parts[1] -ForegroundColor Gray
            } else {
                Write-Host "  o $Point" -ForegroundColor Gray
            }
        }
        Write-Host ""
        Write-Host "==========================================================" -ForegroundColor Cyan

        Write-Host "Acciones disponibles:" -ForegroundColor White
        Write-Host "  [1] Activar Tweak (Enable)" -ForegroundColor Green
        Write-Host "  [2] Desactivar Tweak (Disable)" -ForegroundColor Red
        Write-Host "  [3] Volver al menu principal" -ForegroundColor Cyan
        Write-Host ""

        $Action = Read-Host "Elige una accion [1-3]"
        switch ($Action) {
            "1" {
                if ($Tweak.RequiresAdmin -and -not (Test-IsAdmin)) {
                    Write-Host "`n[!] ERROR: Este tweak requiere privilegios de Administrador para ser modificado." -ForegroundColor Red
                    Write-Host "Por favor, vuelve a iniciar la consola de PowerShell como Administrador." -ForegroundColor Yellow
                    Read-Host "`nPresiona Enter para continuar..."
                } else {
                    Write-Host ""
                    & $Tweak.FilePath -Enable
                    # Refresh status
                    $Tweak.Status = & $Tweak.FilePath -Status
                    Read-Host "`nPresiona Enter para continuar..."
                }
            }
            "2" {
                if ($Tweak.RequiresAdmin -and -not (Test-IsAdmin)) {
                    Write-Host "`n[!] ERROR: Este tweak requiere privilegios de Administrador para ser modificado." -ForegroundColor Red
                    Write-Host "Por favor, vuelve a iniciar la consola de PowerShell como Administrador." -ForegroundColor Yellow
                    Read-Host "`nPresiona Enter para continuar..."
                } else {
                    Write-Host ""
                    & $Tweak.FilePath -Disable
                    # Refresh status
                    $Tweak.Status = & $Tweak.FilePath -Status
                    Read-Host "`nPresiona Enter para continuar..."
                }
            }
            "3" {
                $BackToMenu = $true
            }
            Default {
                Write-Host "Opcion invalida." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
}

# Run the menu!
Write-Log "Iniciando menu interactivo de optimizaciones individuales..."
Run-TweaksMenu
Write-Log "Saliendo del menu de optimizaciones."
