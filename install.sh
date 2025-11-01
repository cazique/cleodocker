#!/bin/bash
#
# cleodocker - Instalador Universal para macOS, Linux y Subsistema de Windows para Linux (WSL)
#
# Este script automatiza la instalación completa de cleodocker, incluyendo:
# 1. Detección del sistema operativo y arquitectura.
# 2. Instalación de dependencias (curl, git, Docker, etc.).
# 3. Configuración del entorno (Docker/Colima).
# 4. Clonación del repositorio cleodocker.
# 5. Despliegue de los servicios con Docker Compose.
#
# Uso: curl -fsSL https://raw.githubusercontent.com/cazique/cleodocker/main/install.sh | bash
#

# --- Variables y Constantes ---
export DEBIAN_FRONTEND=noninteractive
readonly LOG_FILE="/tmp/cleodocker_install.log"
readonly CLEO_INSTALL_DIR="${HOME}/.cleodocker"
readonly GITHUB_REPO="https://github.com/cazique/cleodocker.git" # Cambiar por el repo real

# --- Colores para la salida ---
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_BOLD='\033[1m'

# --- Funciones de Utilidad ---

# Imprime un mensaje con formato
# Uso: log_message <LEVEL> "Mensaje"
# NIVELES: INFO, WARN, ERROR, SUCCESS
log_message() {
    local level="$1"
    local message="$2"
    case "$level" in
        INFO)    echo -e "${C_BLUE}INFO:${C_RESET} $message" ;;
        WARN)    echo -e "${C_YELLOW}WARN:${C_RESET} $message" ;;
        ERROR)   echo -e "${C_RED}ERROR:${C_RESET} $message" >&2 ;;
        SUCCESS) echo -e "${C_GREEN}SUCCESS:${C_RESET} $message" ;;
        *)       echo -e "$message" ;;
    esac
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $level - $message" >> "$LOG_FILE"
}

# Ejecuta un comando y registra su salida
# Uso: execute <COMMAND> "Mensaje de éxito"
execute() {
    local cmd="$1"
    local success_msg="$2"
    
    log_message INFO "Ejecutando: $cmd"
    if eval "$cmd" >> "$LOG_FILE" 2>&1; then
        log_message SUCCESS "$success_msg"
    else
        log_message ERROR "Falló la ejecución de: $cmd. Revisa $LOG_FILE para más detalles."
        exit 1
    fi
}

# --- Funciones Principales de Instalación ---

# Detecta el sistema operativo y la arquitectura
detect_os() {
    OS="$(uname -s)"
    ARCH="$(uname -m)"
    log_message INFO "Sistema operativo detectado: $OS"
    log_message INFO "Arquitectura detectada: $ARCH"

    case "$OS" in
        Linux*)
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                OS_ID=$ID
                log_message INFO "Distribución de Linux: $OS_ID"
            else
                log_message WARN "No se pudo determinar la distribución de Linux."
                OS_ID="linux"
            fi
            ;;
        Darwin*)
            OS_ID="macos"
            ;;
        *)
            log_message ERROR "Sistema operativo no soportado: $OS"
            exit 1
            ;;
    esac
}

# Instala las dependencias necesarias
install_dependencies() {
    log_message INFO "Instalando dependencias..."
    case "$OS_ID" in
        ubuntu|debian)
            execute "apt-get update -y" "Repositorios actualizados."
            execute "apt-get install -y curl git apt-transport-https ca-certificates software-properties-common dialog whiptail" "Dependencias base instaladas."
            ;;
        fedora|centos|rhel)
            execute "yum install -y curl git dialog whiptail" "Dependencias base instaladas."
            ;;
        arch)
            execute "pacman -Syu --noconfirm curl git dialog whiptail" "Dependencias base instaladas."
            ;;
        macos)
            if ! command -v brew &> /dev/null; then
                log_message INFO "Homebrew no encontrado. Instalando..."
                execute '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"' "Homebrew instalado."
                # Añadir brew al PATH para la sesión actual
                if [[ "$ARCH" == "arm64" ]]; then
                    eval "$(/opt/homebrew/bin/brew shellenv)"
                else
                    eval "$(/usr/local/bin/brew shellenv)"
                fi
            fi
            
            # --- CORRECCIÓN PARA MACOS ---
            # Instalar solo git y dialog, ya que whiptail no existe en Homebrew.
            log_message INFO "Instalando dependencias de Homebrew: git y dialog..."
            execute "brew install git dialog" "Dependencias base (git y dialog) instaladas."

            # Whiptail no está disponible en Homebrew. Creamos un enlace simbólico a dialog
            # ya que es compatible en su mayoría para operaciones básicas de TUI.
            if ! command -v whiptail &> /dev/null; then
                log_message INFO "Creando enlace simbólico para emular 'whiptail' usando 'dialog'..."
                local brew_prefix
                brew_prefix=$(brew --prefix)
                if [ -d "${brew_prefix}/bin" ]; then
                    execute "ln -sf '${brew_prefix}/bin/dialog' '${brew_prefix}/bin/whiptail'" "Enlace simbólico 'whiptail -> dialog' creado."
                else
                    log_message WARN "No se encontró el directorio bin de Homebrew en '${brew_prefix}/bin'. Saltando la creación del symlink."
                fi
            else
                log_message SUCCESS "'whiptail' ya está disponible."
            fi
            ;;
        *)
            log_message ERROR "Distribución no soportada para instalación automática de dependencias."
            exit 1
            ;;
    esac
}

# Clona o actualiza el repositorio de cleodocker
setup_repo() {
    if [ -d "$CLEO_INSTALL_DIR" ]; then
        log_message INFO "Directorio de cleodocker encontrado. Actualizando..."
        execute "cd '$CLEO_INSTALL_DIR' && git pull" "Repositorio actualizado."
    else
        log_message INFO "Clonando el repositorio de cleodocker..."
        execute "git clone '$GITHUB_REPO' '$CLEO_INSTALL_DIR'" "Repositorio clonado en $CLEO_INSTALL_DIR."
    fi
    cd "$CLEO_INSTALL_DIR" || exit 1
}

# Instala Docker o Colima según el SO
setup_docker_environment() {
    log_message INFO "Configurando el entorno de contenedores..."
    if ! command -v docker &> /dev/null; then
        log_message INFO "Docker no encontrado. Ejecutando script de instalación de Docker..."
        # El script de módulos se encargará de la lógica específica del SO
        execute "bash modules/docker_setup.sh" "Entorno Docker configurado."
    else
        log_message SUCCESS "Docker ya está instalado."
    fi
    
    if [ "$OS_ID" == "macos" ]; then
        if ! command -v colima &> /dev/null; then
            log_message INFO "Colima no encontrado. Ejecutando script de gestión de Colima..."
            execute "bash modules/colima_manager.sh install" "Colima instalado y configurado."
        else
            log_message SUCCESS "Colima ya está instalado."
        fi
    fi
}

# Crea el enlace simbólico para el comando 'cleo'
create_cli_symlink() {
    local cli_path="$CLEO_INSTALL_DIR/cleo"
    local symlink_path="/usr/local/bin/cleo"
    
    if [ -f "$cli_path" ]; then
        log_message INFO "Creando enlace simbólico para el CLI en $symlink_path..."
        if [ -w "/usr/local/bin" ]; then
            execute "ln -sf '$cli_path' '$symlink_path'" "Enlace simbólico 'cleo' creado."
        else
            log_message WARN "No se tienen permisos para escribir en /usr/local/bin. Intentando con sudo."
            execute "sudo ln -sf '$cli_path' '$symlink_path'" "Enlace simbólico 'cleo' creado con sudo."
        fi
        log_message INFO "Ahora puedes usar el comando 'cleo' globalmente."
    else
        log_message ERROR "El script CLI 'cleo' no se encontró en $cli_path."
        exit 1
    fi
}

# Despliega la aplicación con Docker Compose
deploy_application() {
    log_message INFO "Desplegando los servicios de cleodocker con Docker Compose..."
    cd "$CLEO_INSTALL_DIR" || { log_message ERROR "No se pudo cambiar al directorio $CLEO_INSTALL_DIR"; exit 1; }

    # Verificar si Docker Compose V2 (plugin) está disponible
    if docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
    # Verificar si Docker Compose V1 (standalone) está disponible
    elif command -v docker-compose &> /dev/null; then
        COMPOSE_CMD="docker-compose"
    else
        log_message ERROR "No se encontró ni 'docker compose' (V2) ni 'docker-compose' (V1)."
        log_message INFO "Por favor, instala Docker Compose y vuelve a intentarlo."
        exit 1
    fi
    
    log_message INFO "Usando '$COMPOSE_CMD' para el despliegue."
    execute "$COMPOSE_CMD up -d --build" "Servicios de cleodocker desplegados."
}

# --- Flujo Principal ---
main() {
    # Limpiar log anterior
    rm -f "$LOG_FILE"
    
    echo -e "${C_BOLD}${C_GREEN}--- Iniciando Instalación de cleodocker ---${C_RESET}"
    echo "Se registrará un log detallado en: $LOG_FILE"
    
    # Comprobar si se ejecuta como root
    if [ "$(id -u)" -ne 0 ]; then
        log_message WARN "Este script se está ejecutando sin privilegios de root."
        log_message WARN "Se podría solicitar la contraseña para comandos que requieran 'sudo'."
    fi
    
    detect_os
    install_dependencies
    setup_repo
    setup_docker_environment
    deploy_application
    create_cli_symlink
    
    echo
    log_message SUCCESS "¡Instalación de cleodocker completada!"
    echo -e "Panel web disponible en: ${C_YELLOW}http://localhost:8080${C_RESET}"
    echo -e "Usa el comando '${C_GREEN}cleo help${C_RESET}' para ver las opciones de la línea de comandos."
    echo -e "${C_BOLD}¡Gracias por usar cleodocker!${C_RESET}"
}

# Ejecutar el script
main "$@"