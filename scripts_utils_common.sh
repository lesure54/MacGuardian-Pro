#!/bin/bash

# Variables globales
readonly SCRIPT_VERSION="3.0"
readonly SCRIPT_DATE="2025-04-17 09:53:09"
readonly CURRENT_USER="lesure54"

# Couleurs pour le terminal
declare -r RED='\033[0;31m'
declare -r GREEN='\033[0;32m'
declare -r YELLOW='\033[1;33m'
declare -r BLUE='\033[0;34m'
declare -r NC='\033[0m'

# Fonction de logging
log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${BLUE}[${timestamp}]${NC} ${!level}[${level}]${NC} ${message}"
}

# Vérification des prérequis
check_prerequisites() {
    local missing_tools=()
    
    for tool in "$@"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log "ERROR" "Outils manquants : ${missing_tools[*]}"
        return 1
    fi
    
    return 0
}

# Gestion des erreurs
handle_error() {
    local exit_code=$1
    local line_no=$2
    log "ERROR" "Erreur à la ligne ${line_no} (code ${exit_code})"
    exit $exit_code
}

# Vérification de l'espace disque
check_disk_space() {
    local min_space=$1
    local available=$(df / | awk 'NR==2 {print $4}')
    
    if [ "$available" -lt "$min_space" ]; then
        log "WARNING" "Espace disque faible : ${available}K disponible"
        return 1
    fi
    
    return 0
}

# Création de backup
create_backup() {
    local source=$1
    local dest=$2
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    tar -czf "${dest}/backup_${timestamp}.tar.gz" "$source" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        log "SUCCESS" "Backup créé : backup_${timestamp}.tar.gz"
        return 0
    else
        log "ERROR" "Échec de la création du backup"
        return 1
    fi
}

# Nettoyage des anciens fichiers
cleanup_old_files() {
    local directory=$1
    local days=$2
    
    find "$directory" -type f -mtime +"$days" -delete
    
    if [ $? -eq 0 ]; then
        log "SUCCESS" "Nettoyage des anciens fichiers terminé"
        return 0
    else
        log "ERROR" "Échec du nettoyage des anciens fichiers"
        return 1
    fi
}