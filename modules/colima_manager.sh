#!/bin/bash
#
# modules/colima_manager.sh - Gestiona la instalación y configuración de Colima en macOS
#

# --- Funciones de Utilidad ---
log_colima() {
    echo "COLIMA_MANAGER: $1"
}

# Función para instalar Colima y Docker
install_colima() {
    if ! command -v brew &> /dev/null; then
        log_colima "Error: Homebrew no está instalado. Instálalo primero."
        exit 1
    fi
    
    log_colima "Instalando Colima y cliente Docker..."
    brew install colima docker docker-compose
    
    log_colima "Instalación completada."
    start_colima # Iniciar después de instalar
}

# Función para iniciar Colima con configuración optimizada
start_colima() {
    log_colima "Iniciando Colima..."
    # Detectar recursos para una configuración por defecto inteligente
    local cpus=$(sysctl -n hw.ncpu)
    local mem_gb=$(($(sysctl -n hw.memsize) / 1024 / 1024 / 1024))
    
    # Asignar la mitad de los recursos, con un máximo razonable
    local colima_cpus=$((cpus / 2))
    local colima_mem=$((mem_gb / 2))
    
    # Mínimos
    [ "$colima_cpus" -lt 2 ] && colima_cpus=2
    [ "$colima_mem" -lt 2 ] && colima_mem=2
    # Máximos
    [ "$colima_cpus" -gt 8 ] && colima_cpus=8
    [ "$colima_mem" -gt 16 ] && colima_mem=16

    log_colima "Configuración recomendada: ${colima_cpus} CPUs, ${colima_mem}GB RAM."
    
    # Iniciar Colima si no está en ejecución
    if ! colima status &> /dev/null; then
        colima start --cpu "$colima_cpus" --memory "$colima_mem" --arch "$(uname -m)" --vm-type=vz --mount-type=virtiofs
        log_colima "Colima iniciado."
    else
        log_colima "Colima ya está en ejecución."
    fi
}

# Función para detener Colima
stop_colima() {
    log_colima "Deteniendo Colima..."
    colima stop
    log_colima "Colima detenido."
}

# --- Flujo Principal ---
case "$1" in
    install)
        install_colima
        ;;
    start)
        start_colima
        ;;
    stop)
        stop_colima
        ;;
    *)
        echo "Uso: $0 {install|start|stop}"
        exit 1
        ;;
esac