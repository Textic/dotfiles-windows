param(
    [switch]$GetInfo,
    [switch]$Status,
    [switch]$Enable,
    [switch]$Disable
)

# Metadata definitions
$Name = "Compresion de Memoria (MMAgent)"
$Description = "Administra la compresion de memoria virtual de Windows para ahorrar RAM o liberar CPU."

$WhyEnable = @(
    "Tienes 8 GB o 16 GB de RAM: Con esta cantidad, la compresion es vital. Si la desactivas, Windows se quedara sin RAM fisica rapidamente y empezara a usar el disco duro (Pagefile), lo que ralentizara la PC por completo en cuanto abras muchas pestanas de navegador o un juego pesado.",
    "Usas una Laptop y priorizas la bateria: Aunque la CPU trabaja un poco mas comprimiendo, evita que el disco duro se active constantemente para leer/escribir datos virtuales, lo que a menudo ahorra mas energia.",
    "Uso general de la PC: Si juego de forma casual, trabajas en oficina, programas, o ves contenido multimedia, la compresion de Windows es muy eficiente y ni notaras que esta encendida."
)

$WhyDisable = @(
    "Tienes mucha memoria RAM (32 GB o mas): Al tener RAM de sobra, no necesitas que Windows gaste recursos comprimiendola para ahorrar espacio.",
    "Buscas exprimir los milisegundos en Gaming Competitivo: La compresion y descompresion de datos usa ciclos de la CPU. Desactivarlo puede eliminar ligeros tirones (stuttering) o caidas de FPS de un milisegundo (frametime drops) en juegos pesados.",
    "Trabajas con Audio Profesional (DAWs): En la produccion musical en tiempo real, cualquier proceso en segundo plano de la CPU que cause latencia es un enemigo.",
    "Tu procesador es viejo o de gama baja pero tienes buena RAM: Si la CPU sufre para procesar las tareas diarias, quitarle el peso de comprimir la memoria le dara un respiro."
)

function Test-IsAdmin {
    $Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object Security.Principal.WindowsPrincipal($Identity)
    return $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

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
        RequiresAdmin = $true
    }
    exit
}

if ($Status) {
    return (Get-CurrentStatus)
}

if ($Enable) {
    if (-not (Test-IsAdmin)) {
        Write-Error "Este comando requiere permisos de Administrador para ser ejecutado."
        exit 1
    }
    Write-Host "Activando compresion de memoria (Enable-MMAgent -MemoryCompression)..." -ForegroundColor Cyan
    try {
        Enable-MMAgent -MemoryCompression -ErrorAction Stop
        Write-Host "Compresion de memoria activada exitosamente." -ForegroundColor Green
    } catch {
        Write-Error "Error al activar la compresion de memoria: $_"
        exit 1
    }
    exit
}

if ($Disable) {
    if (-not (Test-IsAdmin)) {
        Write-Error "Este comando requiere permisos de Administrador para ser ejecutado."
        exit 1
    }
    Write-Host "Desactivando compresion de memoria (Disable-MMAgent -MemoryCompression)..." -ForegroundColor Cyan
    try {
        Disable-MMAgent -MemoryCompression -ErrorAction Stop
        Write-Host "Compresion de memoria desactivada exitosamente." -ForegroundColor Green
    } catch {
        Write-Error "Error al desactivar la compresion de memoria: $_"
        exit 1
    }
    exit
}
