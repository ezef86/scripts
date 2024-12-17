#!/bin/bash
set -euo pipefail

encabezado() {
    echo "=============================="
    echo "Informe del sistema: $(hostname -s)" || return 1
    echo "=============================="
}

fecha_hora() {
    echo "Fecha y Hora: $(date '+%d/%m/%Y %H:%M:%S')" || return 1
}

usuarios() {
    echo "Lista de usuarios conectados: "
    who | awk '{print $1}' || return 1
}

info() {
    echo "Información del Sistema:"
    echo "Sistema Operativo: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)" || return 1
    echo "Kernel: $(uname -r)" || return 1
    echo "Arquitectura: $(uname -m)" || return 1
    echo "Estado de Actualizaciones del Sistema:"
    if command -v apt &>/dev/null; then
        apt list --upgradable 2>/dev/null | wc -l | awk '{print "Paquetes pendientes de actualización: " $1-1}' || return 1
    elif command -v dnf &>/dev/null; then
        dnf check-update --quiet | wc -l | awk '{print "Paquetes pendientes de actualización: " $1}' || return 1
    fi
    echo "Últimos eventos de reinicio y apagado:"
    last -x reboot shutdown | head -n 5 || return 1
}

cpu() {
    echo "Información del CPU:"
    echo "Modelo de CPU:"
    lscpu | grep "Model name" | cut -d: -f2- | sed 's/^[ \t]*//' || return 1
    echo "Núcleos físicos: $(nproc --all)" || return 1
}

disco() {
    local point=${1:-"/"}  # Si no se pasa ningún argumento se usará el directorio root "/"
    # Chequear si el punto de montaje es válido:
    if ! df "$point" >/dev/null 2>&1; then
        echo "Error: El punto de montaje '$point' no es válido."
        return 1
    fi
    local space=$(df -h "$point" | awk 'NR > 1 {print $5}') || {
        echo "Error: No se pudo obtener el uso del disco para '$point'."
        return 1
    }
    echo "Uso del disco en el punto de montaje $point: $space"
}

ram() {
    echo "Información de Memoria RAM:"
    free -h | awk 'NR==2 {printf "Total: %s, Usado: %s, Libre: %s\n", $2, $3, $4}' || return 1
}

red() {
    echo "Interfaces de Red Activas:"
    ip -brief addr show | awk '$3 != "" {print $1 ": " $3}' || return 1
}

proceso() {
    local proceso
    while true; do
        read -p "Ingrese el proceso que desea buscar: " proceso
        [[ -z "$proceso" ]] && { echo "Debe ingresar un nombre de proceso"; continue; }
        [[ ${#proceso} -eq 1 ]] && { echo "Por favor, ingrese un nombre de proceso más específico."; continue; }
        echo "Los datos del proceso son:"
        if pgrep -f "$proceso" >/dev/null; then
            ps -fp $(pgrep -f "$proceso")
            return 0
        else
            echo "No se encontraron procesos con el nombre '$proceso'. Vuelve a intentar"
        fi
    done
}

main() {
    encabezado
    fecha_hora
    usuarios
    echo "=============================="
    info
    echo "=============================="
    cpu
    echo "=============================="
    disco
    echo "=============================="
    ram
    echo "=============================="
    red
    echo "=============================="
    proceso
    echo "Fin del informe"
}

if [[ $# -eq 0 ]]; then
    main
else
    case "$1" in
        "encabezado") encabezado ;;
        "fecha_hora") fecha_hora ;;
        "usuarios") usuarios ;;
        "info") info ;;
        "cpu") cpu ;;
        "disco") 
            if [[ $# -eq 2 ]]; then
                disco "$2"  # Luego del parámetro "disco" pasamos un argumento para el punto de montaje a buscar.
            else
                disco
            fi
            ;;
        "ram") ram ;;
        "red") red ;;
        "proceso") proceso ;;
        *) echo "Ingrese uno de los siguientes parámetros para el script $0: [encabezado|fecha_hora|usuarios|info|cpu|disco|ram|proceso]" && exit 1 ;;
    esac
fi