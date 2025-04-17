#!/bin/bash

# Méta-informations
readonly VERSION="3.0"
readonly LAST_UPDATED="2025-04-17 09:53:09"
readonly CURRENT_USER="lesure54"
readonly CURRENT_TIME=$(date -u +"%Y-%m-%d %H:%M:%S")

# Détection de l'architecture
ARCH=$(uname -m)
IS_M1=false
if [ "$ARCH" = "arm64" ]; then
    IS_M1=true
fi

# Configuration des chemins
readonly BASE_DIR="$HOME/.macguardian"
readonly CONFIG_DIR="$BASE_DIR/config"
readonly LOGS_DIR="$BASE_DIR/logs"
readonly BACKUP_DIR="$BASE_DIR/backups"
readonly MODULES_DIR="$(dirname "$0")/modules"

# Couleurs et styles
declare -A COLORS=(
    ["INFO"]='\033[0;34m'     # Bleu
    ["SUCCESS"]='\033[0;32m'   # Vert
    ["WARNING"]='\033[1;33m'   # Jaune
    ["ERROR"]='\033[0;31m'     # Rouge
    ["HEADER"]='\033[1;35m'    # Magenta
    ["RESET"]='\033[0m'
)

# Fonction d'initialisation spécifique M1
init_m1_optimization() {
    if [ "$IS_M1" = true ]; then
        log "INFO" "Détection processeur Apple Silicon M1 - Optimisation activée"
        
        # Optimisations spécifiques M1
        sudo nvram boot-args="serverperfmode=1 $(nvram boot-args 2>/dev/null | cut -f 2-)"
        defaults write -g NSDocumentSaveNewDocumentsToCloud -bool false
        sudo trimforce enable &>/dev/null
        
        # Optimisation de Rosetta 2 si installé
        if [ -f "/Library/Apple/usr/share/rosetta/rosetta" ]; then
            log "INFO" "Optimisation de Rosetta 2"
            defaults write com.apple.RosettaUpdateCore AutoUpdate -bool true
        fi
    fi
}

# Fonction de log
log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${COLORS[$level]}[${timestamp}] [$level] ${message}${COLORS[RESET]}"
}

# Vérification système
check_system() {
    if [[ $(sw_vers -productVersion) < "11.0" ]]; then
        log "ERROR" "MacGuardian Pro nécessite macOS Big Sur (11.0) ou plus récent"
        exit 1
    }
    
    if [[ $EUID -ne 0 ]]; then
        log "ERROR" "Ce script doit être exécuté en tant qu'administrateur (sudo)"
        exit 1
    }
    
    local free_space=$(df -h / | awk 'NR==2 {print $4}' | sed 's/Gi//')
    if (( $(echo "$free_space < 5" | bc -l) )); then
        log "WARNING" "Espace disque faible : ${free_space}GB disponible"
    fi
}

# Optimisation spécifique M1
optimize_m1_performance() {
    if [ "$IS_M1" = true ]; then
        log "INFO" "Application des optimisations M1..."
        
        sudo purge
        sudo pmset -a gpuswitch 2
        find /Applications -name "Info.plist" -exec plutil -convert xml1 {} \;
        
        log "SUCCESS" "Optimisations M1 appliquées"
    fi
}

# Maintenance principale
main_maintenance() {
    log "INFO" "Démarrage de la maintenance..."
    
    if [ "$IS_M1" = true ]; then
        optimize_m1_performance
    fi
    
    sudo periodic daily weekly monthly
    sudo rm -rf /Library/Caches/*
    rm -rf ~/Library/Caches/*
    
    sudo defaults write com.apple.frameworks.diskimages skip-verify -bool true
    sudo defaults write com.apple.CrashReporter DialogType none
    
    log "SUCCESS" "Maintenance terminée"
}

# Menu principal
show_menu() {
    clear
    echo -e "${COLORS[HEADER]}"
    echo "================================"
    echo "   MacGuardian Pro v$VERSION"
    echo "   Architecture: $ARCH"
    if [ "$IS_M1" = true ]; then
        echo "   ✨ Optimisé pour Apple Silicon"
    fi
    echo "   Utilisateur: $CURRENT_USER"
    echo "   Date: $CURRENT_TIME"
    echo "================================"
    echo -e "${COLORS[RESET]}"
    echo "1. Maintenance complète"
    echo "2. Scan de sécurité"
    echo "3. Optimisation système"
    echo "4. Monitoring système"
    echo "5. Maintenance avancée"
    echo "6. Quitter"
    echo
    read -p "Choix : " choice
    
    case $choice in
        1) main_maintenance ;;
        2) "$MODULES_DIR/security_scanner.sh" ;;
        3) "$MODULES_DIR/system_optimization.sh" ;;
        4) "$MODULES_DIR/monitoring.sh" ;;
        5) "$MODULES_DIR/maintenance_advanced.sh" ;;
        6) exit 0 ;;
        *) log "ERROR" "Choix invalide" ;;
    esac
}

# Initialisation
mkdir -p "$BASE_DIR" "$CONFIG_DIR" "$LOGS_DIR" "$BACKUP_DIR"
check_system
init_m1_optimization

# Boucle principale
while true; do
    show_menu
done
