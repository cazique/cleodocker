#!/bin/bash
#
# modules/gpu_detector.sh - Detecta la GPU y sugiere configuraciones de Docker
#

detect_gpu() {
    echo "--- Detección de GPU ---"
    
    if command -v nvidia-smi &> /dev/null; then
        echo "GPU NVIDIA detectada."
        nvidia-smi --query-gpu=gpu_name,driver_version,memory.total --format=csv,noheader
        echo "Recomendación: Instala 'nvidia-docker2' y usa '--gpus all' en tus comandos de Docker."
        
    elif lspci 2>/dev/null | grep -i 'vga.*amd' > /dev/null; then
        echo "GPU AMD detectada."
        echo "Recomendación: Usa el flag '--device=/dev/kfd --device=/dev/dri' para pasar la GPU al contenedor (requiere drivers ROCm en el host)."
        
    elif lspci 2>/dev/null | grep -i 'vga.*intel' > /dev/null; then
        echo "GPU Intel integrada detectada."
        echo "Recomendación: Usa el flag '--device=/dev/dri' para habilitar la aceleración de video (Quick Sync)."
        
    elif [[ "$(uname -s)" == "Darwin" ]]; then
        echo "Apple Silicon con GPU integrada detectado."
        sysctl -n machdep.cpu.brand_string
        echo "Recomendación: La aceleración de hardware está disponible a través del framework VideoToolbox en contenedores compatibles."
        
    else
        echo "No se pudo detectar una GPU compatible o la herramienta 'lspci' no está disponible."
    fi
    
    echo "------------------------"
}

detect_gpu