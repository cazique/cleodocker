#
# cleodocker - Instalador para Windows con PowerShell
#
# Este script automatiza la instalación de cleodocker en Windows, utilizando WSL2.
# 1. Verifica y activa las características de Windows necesarias (WSL, Virtual Machine Platform).
# 2. Instala WSL y una distribución de Linux (Ubuntu por defecto).
# 3. Instala Docker Desktop o configura Docker Engine dentro de WSL.
# 4. Clona el repositorio de cleodocker dentro de WSL.
# 5. Ejecuta el instalador de Linux (install.sh) dentro de WSL.
#
# Uso: Abrir PowerShell como Administrador y ejecutar:
# irm https://raw.githubusercontent.com/tu-usuario/cleodocker/main/install.ps1 | iex
#

# --- Configuración ---
$LogFile = "$env:TEMP\cleodocker_install.log"
$CleoInstallDir = "$HOME\.cleodocker"
$GithubRepo = "https://github.com/tu-usuario/cleodocker.git" # Cambiar por el repo real
$WslDistro = "Ubuntu"

# --- Funciones de Utilidad ---

# Escribe un mensaje en la consola y en el archivo de log.
function Log-Message {
    param (
        [string]$Level,
        [string]$Message
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $FormattedMessage = "$Timestamp - $Level - $Message"
    
    switch ($Level) {
        "INFO"    { Write-Host "[INFO] $Message" -ForegroundColor Cyan }
        "WARN"    { Write-Host "[WARN] $Message" -ForegroundColor Yellow }
        "ERROR"   { Write-Host "[ERROR] $Message" -ForegroundColor Red }
        "SUCCESS" { Write-Host "[SUCCESS] $Message" -ForegroundColor Green }
        default   { Write-Host $Message }
    }
    
    Add-Content -Path $LogFile -Value $FormattedMessage
}

# Ejecuta un comando y maneja errores.
function Execute-Command {
    param (
        [scriptblock]$Command,
        [string]$SuccessMessage
    )
    Log-Message "INFO" "Ejecutando: $($Command.ToString())"
    try {
        & $Command
        Log-Message "SUCCESS" $SuccessMessage
    } catch {
        Log-Message "ERROR" "Falló la ejecución. Revisa el log: $LogFile"
        Log-Message "ERROR" $_.Exception.Message
        Add-Content -Path $LogFile -Value $_.Exception.ToString()
        exit 1
    }
}

# --- Funciones Principales ---

# Verifica si el script se está ejecutando como Administrador.
function Check-Admin {
    Log-Message "INFO" "Verificando privilegios de administrador..."
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Log-Message "ERROR" "Este script requiere privilegios de Administrador."
        Log-Message "INFO" "Por favor, abre PowerShell como Administrador y vuelve a ejecutarlo."
        exit 1
    }
    Log-Message "SUCCESS" "Ejecutando como Administrador."
}

# Habilita las características de Windows necesarias.
function Enable-WindowsFeatures {
    Log-Message "INFO" "Habilitando características de Windows (WSL y Virtual Machine Platform)..."
    $features = @("Microsoft-Windows-Subsystem-Linux", "VirtualMachinePlatform")
    $needsReboot = $false
    foreach ($feature in $features) {
        $status = Get-WindowsOptionalFeature -Online -FeatureName $feature
        if ($status.State -ne "Enabled") {
            Log-Message "INFO" "Habilitando $feature..."
            Execute-Command -Command { Dism.exe /online /enable-feature /featurename:$feature /all /norestart } -SuccessMessage "$feature habilitado."
            $needsReboot = $true
        } else {
            Log-Message "SUCCESS" "$feature ya está habilitado."
        }
    }

    if ($needsReboot) {
        Log-Message "WARN" "Se requiere un reinicio para completar la instalación de las características de Windows."
        $choice = Read-Host "Reiniciar ahora? (s/n)"
        if ($choice -eq 's') {
            Restart-Computer -Force
        } else {
            Log-Message "ERROR" "Reinicio cancelado. La instalación no puede continuar."
            exit 1
        }
    }
}

# Instala WSL y la distribución de Linux.
function Install-Wsl {
    Log-Message "INFO" "Verificando la instalación de WSL..."
    $wslStatus = wsl --status 2>&1
    if ($LASTEXITCODE -ne 0) {
        Log-Message "INFO" "Instalando WSL..."
        Execute-Command -Command { wsl --install -d $WslDistro } -SuccessMessage "WSL y $WslDistro instalados."
        Log-Message "WARN" "Puede que se requiera un reinicio. Si el script falla, por favor reinicia y vuelve a ejecutarlo."
    } else {
        Log-Message "SUCCESS" "WSL ya está instalado."
        # Asegura que la distro esté instalada
        $distros = wsl -l -q
        if (-not ($distros -match $WslDistro)) {
            Log-Message "INFO" "Instalando la distribución $WslDistro..."
            Execute-Command -Command { wsl --install -d $WslDistro } -SuccessMessage "$WslDistro instalado."
        }
    }
    # Establecer WSL 2 como versión por defecto
    Execute-Command -Command { wsl --set-default-version 2 } -SuccessMessage "WSL 2 establecido como versión por defecto."
}

# Instala Docker Desktop.
function Install-DockerDesktop {
    Log-Message "INFO" "Verificando Docker Desktop..."
    if (-not (Get-Command "docker" -ErrorAction SilentlyContinue)) {
        Log-Message "INFO" "Docker Desktop no encontrado. Descargando e instalando..."
        $installerPath = "$env:TEMP\Docker.Desktop.Installer.exe"
        $downloadUrl = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
        
        Execute-Command -Command { Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath } -SuccessMessage "Instalador de Docker Desktop descargado."
        Execute-Command -Command { Start-Process $installerPath -ArgumentList "install", "--quiet" -Wait } -SuccessMessage "Docker Desktop instalado. Por favor, inicia la aplicación si no se abre automáticamente."
        
        Log-Message "INFO" "Asegúrate de que la integración con WSL esté habilitada en la configuración de Docker Desktop."
        Log-Message "INFO" "El script continuará en 15 segundos..."
        Start-Sleep -Seconds 15
    } else {
        Log-Message "SUCCESS" "Docker ya está instalado."
    }
}

# Ejecuta el instalador de Linux dentro de WSL.
function Run-LinuxInstaller {
    Log-Message "INFO" "Iniciando la instalación de cleodocker dentro de WSL..."
    $wslCommand = "curl -fsSL https://raw.githubusercontent.com/tu-usuario/cleodocker/main/install.sh | bash"
    
    Log-Message "INFO" "Ejecutando el siguiente comando en WSL: $wslCommand"
    try {
        # Ejecuta el comando en WSL y muestra la salida en tiempo real
        wsl -d $WslDistro -e bash -c $wslCommand
        Log-Message "SUCCESS" "La instalación dentro de WSL parece haber finalizado."
    } catch {
        Log-Message "ERROR" "Ocurrió un error al ejecutar el instalador de Linux en WSL."
        Log-Message "ERROR" $_.Exception.Message
        exit 1
    }
}

# --- Flujo Principal ---
function Main {
    # Limpiar log anterior
    if (Test-Path $LogFile) {
        Remove-Item $LogFile
    }

    Write-Host "--- Iniciando Instalación de cleodocker para Windows ---" -ForegroundColor Green
    Write-Host "Se registrará un log detallado en: $LogFile"
    
    Check-Admin
    Enable-WindowsFeatures
    Install-Wsl
    Install-DockerDesktop
    Run-LinuxInstaller

    Write-Host ""
    Log-Message "SUCCESS" "¡Instalación de cleodocker completada!"
    Write-Host "Panel web disponible en: http://localhost:8080"
    Write-Host "Para usar el CLI, abre tu terminal de WSL ($WslDistro) y ejecuta 'cleo help'."
    Write-Host "¡Gracias por usar cleodocker!"
}

# Ejecutar el script
Main