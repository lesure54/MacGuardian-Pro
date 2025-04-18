#!/bin/bash

# ========================================================
# Script de Nettoyage Mac - MacGuardian Pro
# ========================================================
# Ce script permet de nettoyer votre Mac des fichiers temporaires, 
# caches et autres fichiers inutiles, ainsi que de vérifier et
# installer les mises à jour système et du script lui-même.
# 
# ATTENTION: Utilisez ce script à vos risques et périls. 
# Faites une sauvegarde avant de l'exécuter.
# ========================================================
# Date de dernière mise à jour: 2025-04-18 10:02:25
# Créé par: lesure54
# Exécuté par: rikasa288
# ========================================================

# ========================================================
# Configuration du script
# ========================================================
VERSION="2.0"
GITHUB_REPO="lesure54/MacGuardian-Pro"
UPDATE_URL="https://api.github.com/repos/$GITHUB_REPO/releases/latest"
SCRIPT_NAME="$(basename "$0")"
SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$SCRIPT_NAME"
CURRENT_DATE="2025-04-18 10:02:25"
CURRENT_USER="rikasa288"
AUTHOR="lesure54"

# Configuration des dossiers
USER_HOME="$HOME"
CACHE_DIR="/Library/Caches"
USER_CACHE_DIR="$USER_HOME/Library/Caches"
TEMP_DIR="/private/var/tmp"
TMP_DIR="/tmp"
LOG_DIR="/private/var/log"
DOWNLOADS_DIR="$USER_HOME/Downloads"
TRASH_DIR="$USER_HOME/.Trash"

# Configuration des logs
LOG_BASE_DIR="$USER_HOME/mac_cleaner_logs"
LOG_FILE="$LOG_BASE_DIR/clean_$(date +%Y%m%d_%H%M%S).log"
ERROR_LOG_FILE="$LOG_BASE_DIR/error_$(date +%Y%m%d_%H%M%S).log"

# Configuration des couleurs
COLOR_GREEN="\033[0;32m"
COLOR_RED="\033[0;31m"
COLOR_YELLOW="\033[0;33m"
COLOR_BLUE="\033[0;34m"
COLOR_RESET="\033[0m"

# Configuration des applications à nettoyer
declare -a APPS_TO_CLEAN=(
    "$USER_HOME/Library/Containers/com.apple.mail/Data/Library/Caches"
    "$USER_HOME/Library/Caches/com.apple.Safari"
    "$USER_HOME/Library/Caches/com.google.Chrome"
    "$USER_HOME/Library/Caches/com.microsoft.VSCode"
    "$USER_HOME/Library/Caches/com.spotify.client"
)

# ========================================================
# Fonctions d'utilitaire
# ========================================================

# Fonction pour afficher les messages en couleur
# Arguments:
#   $1 - Couleur du message (green, red, yellow, blue)
#   $2 - Message à afficher
print_message() {
    local color=$1
    local message=$2
    case $color in
        "green") echo -e "${COLOR_GREEN}$message${COLOR_RESET}" ;;
        "red") echo -e "${COLOR_RED}$message${COLOR_RESET}" ;;
        "yellow") echo -e "${COLOR_YELLOW}$message${COLOR_RESET}" ;;
        "blue") echo -e "${COLOR_BLUE}$message${COLOR_RESET}" ;;
        *) echo -e "$message" ;;
    esac
}

# Fonction pour journaliser les messages
# Arguments:
#   $1 - Message à journaliser
#   $2 - Fichier de log où écrire le message
log_message() {
    local message=$1
    local log_file=$2
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$log_file"
}

# Fonction pour afficher la taille d'un dossier
# Arguments:
#   $1 - Chemin du dossier
# Retourne:
#   Taille du dossier au format humain (ex: 10.5M)
get_folder_size() {
    local folder=$1
    if [ -d "$folder" ]; then
        du -sh "$folder" 2>/dev/null | cut -f1
    else
        echo "0B"
    fi
}

# Fonction pour demander confirmation à l'utilisateur
# Arguments:
#   $1 - Question à poser
# Retourne:
#   0 si l'utilisateur répond oui, 1 sinon
confirm() {
    read -p "$1 (o/n): " reply
    case $reply in
        [Oo]* ) return 0 ;;
        * ) return 1 ;;
    esac
}

# Fonction pour vérifier si une commande s'est exécutée avec succès
# Arguments:
#   $1 - Code de retour de la commande
#   $2 - Message de succès
#   $3 - Message d'erreur
# Retourne:
#   0 si la commande a réussi, 1 sinon
check_command() {
    local cmd_result=$1
    local success_msg=$2
    local error_msg=$3
    
    if [ $cmd_result -eq 0 ]; then
        print_message "green" "$success_msg"
        log_message "$success_msg" "$LOG_FILE"
        return 0
    else
        print_message "red" "$error_msg"
        log_message "$error_msg" "$ERROR_LOG_FILE"
        return 1
    fi
}

# Fonction pour exécuter une commande en tant qu'administrateur
# Arguments:
#   $1 - Commande à exécuter
#   $2 - Message de succès
#   $3 - Message d'erreur
# Retourne:
#   0 si la commande a réussi, 1 sinon
run_as_admin() {
    local cmd=$1
    local success_msg=$2
    local error_msg=$3
    
    sudo $cmd
    check_command $? "$success_msg" "$error_msg"
}

# Fonction pour créer les dossiers de logs
# Crée les dossiers et fichiers nécessaires pour la journalisation
# Quitte le script en cas d'erreur
create_log_directories() {
    mkdir -p "$LOG_BASE_DIR"
    if [ $? -ne 0 ]; then
        print_message "red" "Impossible de créer le dossier de logs: $LOG_BASE_DIR"
        exit 1
    fi
    
    touch "$LOG_FILE" "$ERROR_LOG_FILE"
    if [ $? -ne 0 ]; then
        print_message "red" "Impossible de créer les fichiers de logs"
        exit 1
    fi
    
    log_message "Début du nettoyage" "$LOG_FILE"
    log_message "Script créé par: $AUTHOR" "$LOG_FILE"
    log_message "Script exécuté par: $CURRENT_USER" "$LOG_FILE"
    print_message "green" "Logs créés à: $LOG_FILE"
}

# ========================================================
# Fonctions de nettoyage
# ========================================================

# Fonction pour nettoyer les caches système
# Supprime les fichiers cache du système
clean_system_cache() {
    print_message "blue" "\n1. Nettoyage des caches système"
    local cache_size=$(get_folder_size "$CACHE_DIR")
    print_message "yellow" "Taille des caches système: $cache_size"
    
    if confirm "Voulez-vous nettoyer les caches système?"; then
        print_message "green" "Nettoyage des caches système en cours..."
        sudo rm -rf "$CACHE_DIR"/* 2>> "$ERROR_LOG_FILE"
        check_command $? \
            "Caches système nettoyés. Taille libérée: $cache_size" \
            "Erreur lors du nettoyage des caches système"
    else
        print_message "yellow" "Caches système ignorés."
        log_message "Caches système ignorés." "$LOG_FILE"
    fi
}

# Fonction pour nettoyer les caches utilisateur
# Supprime les fichiers cache de l'utilisateur courant
clean_user_cache() {
    print_message "blue" "\n2. Nettoyage des caches utilisateur"
    local user_cache_size=$(get_folder_size "$USER_CACHE_DIR")
    print_message "yellow" "Taille des caches utilisateur: $user_cache_size"
    
    if confirm "Voulez-vous nettoyer les caches utilisateur?"; then
        print_message "green" "Nettoyage des caches utilisateur en cours..."
        rm -rf "$USER_CACHE_DIR"/* 2>> "$ERROR_LOG_FILE"
        check_command $? \
            "Caches utilisateur nettoyés. Taille libérée: $user_cache_size" \
            "Erreur lors du nettoyage des caches utilisateur"
    else
        print_message "yellow" "Caches utilisateur ignorés."
        log_message "Caches utilisateur ignorés." "$LOG_FILE"
    fi
}

# Fonction pour nettoyer les fichiers temporaires
# Supprime les fichiers temporaires du système
clean_temp_files() {
    print_message "blue" "\n3. Nettoyage des fichiers temporaires"
    local temp_size=$(get_folder_size "$TEMP_DIR")
    local tmp_size=$(get_folder_size "$TMP_DIR")
    print_message "yellow" "Taille des fichiers temporaires: $temp_size (var/tmp) + $tmp_size (tmp)"
    
    if confirm "Voulez-vous nettoyer les fichiers temporaires?"; then
        print_message "green" "Nettoyage des fichiers temporaires en cours..."
        sudo rm -rf "$TEMP_DIR"/* 2>> "$ERROR_LOG_FILE"
        sudo rm -rf "$TMP_DIR"/* 2>> "$ERROR_LOG_FILE"
        check_command $? \
            "Fichiers temporaires nettoyés. Taille libérée: environ $temp_size + $tmp_size" \
            "Erreur lors du nettoyage des fichiers temporaires"
    else
        print_message "yellow" "Fichiers temporaires ignorés."
        log_message "Fichiers temporaires ignorés." "$LOG_FILE"
    fi
}

# Fonction pour nettoyer les logs système
# Supprime les anciens fichiers de log du système
clean_system_logs() {
    print_message "blue" "\n4. Nettoyage des logs système"
    local logs_size=$(get_folder_size "$LOG_DIR")
    print_message "yellow" "Taille des logs système: $logs_size"
    
    if confirm "Voulez-vous nettoyer les logs système?"; then
        print_message "green" "Nettoyage des logs système en cours..."
        sudo rm -rf "$LOG_DIR"/*.log 2>> "$ERROR_LOG_FILE"
        sudo rm -rf "$LOG_DIR"/*.log.* 2>> "$ERROR_LOG_FILE"
        sudo rm -rf "$LOG_DIR"/asl/*.asl 2>> "$ERROR_LOG_FILE"
        check_command $? \
            "Logs système nettoyés. Taille libérée: environ $logs_size" \
            "Erreur lors du nettoyage des logs système"
    else
        print_message "yellow" "Logs système ignorés."
        log_message "Logs système ignorés." "$LOG_FILE"
    fi
}

# Fonction pour nettoyer les téléchargements anciens
# Supprime les fichiers de téléchargement datant de plus de 30 jours
clean_old_downloads() {
    print_message "blue" "\n5. Nettoyage du dossier Téléchargements (fichiers de plus de 30 jours)"
    
    # Vérifier si le dossier existe
    if [ ! -d "$DOWNLOADS_DIR" ]; then
        print_message "yellow" "Dossier Téléchargements introuvable: $DOWNLOADS_DIR"
        log_message "Dossier Téléchargements introuvable: $DOWNLOADS_DIR" "$LOG_FILE"
        return
    fi
    
    local downloads_size=$(find "$DOWNLOADS_DIR" -type f -mtime +30 -exec du -ch {} \; 2>/dev/null | grep total$ | cut -f1)
    
    if [ -z "$downloads_size" ]; then
        downloads_size="0B"
    fi
    
    print_message "yellow" "Taille des téléchargements de plus de 30 jours: $downloads_size"
    
    if confirm "Voulez-vous nettoyer les téléchargements anciens (plus de 30 jours)?"; then
        print_message "green" "Nettoyage des téléchargements anciens en cours..."
        find "$DOWNLOADS_DIR" -type f -mtime +30 -delete 2>> "$ERROR_LOG_FILE"
        check_command $? \
            "Téléchargements anciens nettoyés. Taille libérée: $downloads_size" \
            "Erreur lors du nettoyage des téléchargements anciens"
    else
        print_message "yellow" "Téléchargements anciens ignorés."
        log_message "Téléchargements anciens ignorés." "$LOG_FILE"
    fi
}

# Fonction pour nettoyer les fichiers .DS_Store
# Supprime tous les fichiers .DS_Store du système
clean_ds_store() {
    print_message "blue" "\n6. Nettoyage des fichiers .DS_Store"
    if confirm "Voulez-vous supprimer tous les fichiers .DS_Store?"; then
        print_message "green" "Suppression des fichiers .DS_Store en cours..."
        # Utiliser find plus sécuritairement avec une vérification du type de fichier
        sudo find / -name ".DS_Store" -type f -delete 2>> "$ERROR_LOG_FILE"
        check_command $? \
            "Fichiers .DS_Store supprimés." \
            "Erreur lors de la suppression des fichiers .DS_Store"
    else
        print_message "yellow" "Fichiers .DS_Store ignorés."
        log_message "Fichiers .DS_Store ignorés." "$LOG_FILE"
    fi
}

# Fonction pour vider la corbeille
# Supprime tous les fichiers de la corbeille
empty_trash() {
    print_message "blue" "\n7. Vider la corbeille"
    if confirm "Voulez-vous vider la corbeille?"; then
        print_message "green" "Vidage de la corbeille en cours..."
        rm -rf "$TRASH_DIR"/* 2>> "$ERROR_LOG_FILE"
        check_command $? \
            "Corbeille vidée." \
            "Erreur lors du vidage de la corbeille"
    else
        print_message "yellow" "Corbeille ignorée."
        log_message "Corbeille ignorée." "$LOG_FILE"
    fi
}

# Fonction pour purger les snapshots Time Machine
# Supprime les snapshots locaux de Time Machine
purge_time_machine_snapshots() {
    print_message "blue" "\n8. Purger les snapshots Time Machine locaux"
    if confirm "Voulez-vous purger les snapshots Time Machine locaux?"; then
        print_message "green" "Purge des snapshots Time Machine locaux en cours..."
        
        # Vérifier si tmutil est disponible
        if ! command -v tmutil &> /dev/null; then
            print_message "red" "La commande tmutil n'est pas disponible sur ce système."
            log_message "La commande tmutil n'est pas disponible sur ce système." "$ERROR_LOG_FILE"
            return
        fi
        
        local snapshot_count=0
        local success_count=0
        
        while read -r snapshot; do
            if [ -n "$snapshot" ]; then
                ((snapshot_count++))
                sudo tmutil deletelocalsnapshots "$snapshot" 2>> "$ERROR_LOG_FILE"
                if [ $? -eq 0 ]; then
                    ((success_count++))
                fi
            fi
        done < <(tmutil listlocalsnapshots / 2>/dev/null | cut -d'.' -f4-)
        
        if [ $snapshot_count -eq 0 ]; then
            print_message "yellow" "Aucun snapshot Time Machine local trouvé."
            log_message "Aucun snapshot Time Machine local trouvé." "$LOG_FILE"
        else
            check_command $((success_count == snapshot_count)) \
                "Snapshots Time Machine locaux purgés ($success_count/$snapshot_count)." \
                "Certains snapshots Time Machine n'ont pas pu être purgés ($success_count/$snapshot_count)."
        fi
    else
        print_message "yellow" "Snapshots Time Machine locaux ignorés."
        log_message "Snapshots Time Machine locaux ignorés." "$LOG_FILE"
    fi
}

# Fonction pour nettoyer les caches d'applications spécifiques
# Nettoie les caches des applications définies dans APPS_TO_CLEAN
clean_app_caches() {
    print_message "blue" "\n9. Nettoyer les caches d'applications spécifiques"
    print_message "yellow" "Cette section nettoie les caches des applications courantes."
    
    local app_cleaned=false
    
    for app in "${APPS_TO_CLEAN[@]}"; do
        if [ -d "$app" ]; then
            local app_name=$(basename "$app")
            local app_size=$(get_folder_size "$app")
            print_message "yellow" "Cache de $app_name: $app_size"
            
            if confirm "Voulez-vous nettoyer le cache de $app_name?"; then
                print_message "green" "Nettoyage du cache de $app_name en cours..."
                rm -rf "$app"/* 2>> "$ERROR_LOG_FILE"
                check_command $? \
                    "Cache de $app_name nettoyé. Taille libérée: $app_size" \
                    "Erreur lors du nettoyage du cache de $app_name"
                app_cleaned=true
            else
                print_message "yellow" "Cache de $app_name ignoré."
                log_message "Cache de $app_name ignoré." "$LOG_FILE"
            fi
        fi
    done
    
    if [ "$app_cleaned" = false ]; then
        print_message "yellow" "Aucun cache d'application n'a été nettoyé."
        log_message "Aucun cache d'application n'a été nettoyé." "$LOG_FILE"
    fi
}

# Fonction pour vider le cache DNS
# Vide le cache DNS du système
flush_dns_cache() {
    print_message "blue" "\n10. Vider le cache DNS"
    if confirm "Voulez-vous vider le cache DNS?"; then
        print_message "green" "Vidage du cache DNS en cours..."
        sudo dscacheutil -flushcache 2>> "$ERROR_LOG_FILE"
        local result1=$?
        sudo killall -HUP mDNSResponder 2>> "$ERROR_LOG_FILE"
        local result2=$?
        
        # Vérifier si les deux commandes ont réussi
        if [ $result1 -eq 0 ] && [ $result2 -eq 0 ]; then
            print_message "green" "Cache DNS vidé."
            log_message "Cache DNS vidé." "$LOG_FILE"
        else
            print_message "red" "Erreur lors du vidage du cache DNS."
            log_message "Erreur lors du vidage du cache DNS." "$ERROR_LOG_FILE"
        fi
    else
        print_message "yellow" "Cache DNS ignoré."
        log_message "Cache DNS ignoré." "$LOG_FILE"
    fi
}

# ========================================================
# Fonctions pour la gestion des mises à jour
# ========================================================

# Fonction pour vérifier les mises à jour système macOS
# Vérifie et propose d'installer les mises à jour système
check_system_updates() {
    print_message "blue" "\n11. Vérification des mises à jour système macOS"
    if confirm "Voulez-vous vérifier les mises à jour système?"; then
        print_message "green" "Vérification des mises à jour système en cours..."
        
        # Vérifier si softwareupdate est disponible
        if ! command -v softwareupdate &> /dev/null; then
            print_message "red" "La commande softwareupdate n'est pas disponible sur ce système."
            log_message "La commande softwareupdate n'est pas disponible." "$ERROR_LOG_FILE"
            return
        fi
        
        # Liste les mises à jour disponibles
        softwareupdate --list > /tmp/mac_updates.txt 2>> "$ERROR_LOG_FILE"
        
        if grep -q "No new software available" /tmp/mac_updates.txt || [ $? -ne 0 ]; then
            print_message "yellow" "Aucune mise à jour système disponible."
            log_message "Aucune mise à jour système disponible." "$LOG_FILE"
        else
            print_message "green" "Mises à jour système disponibles :"
            cat /tmp/mac_updates.txt
            log_message "Mises à jour système disponibles." "$LOG_FILE"
            
            if confirm "Voulez-vous installer les mises à jour système disponibles?"; then
                print_message "green" "Installation des mises à jour système en cours..."
                sudo softwareupdate --install --all 2>> "$ERROR_LOG_FILE"
                check_command $? \
                    "Mises à jour système installées." \
                    "Erreur lors de l'installation des mises à jour système."
            else
                print_message "yellow" "Installation des mises à jour système ignorée."
                log_message "Installation des mises à jour système ignorée." "$LOG_FILE"
            fi
        fi
        
        # Nettoyer le fichier temporaire
        rm -f /tmp/mac_updates.txt
    else
        print_message "yellow" "Vérification des mises à jour système ignorée."
        log_message "Vérification des mises à jour système ignorée." "$LOG_FILE"
    fi
}

# Fonction pour vérifier les mises à jour du script sur GitHub
# Vérifie, télécharge et installe les mises à jour de MacGuardian Pro
check_script_updates() {
    print_message "blue" "\n12. Vérification des mises à jour du script (MacGuardian Pro)"
    if confirm "Voulez-vous vérifier les mises à jour du script?"; then
        print_message "green" "Vérification des mises à jour de MacGuardian Pro en cours..."
        
        # Vérifier si curl est disponible
        if ! command -v curl &> /dev/null; then
            print_message "red" "La commande curl n'est pas disponible sur ce système."
            log_message "La commande curl n'est pas disponible." "$ERROR_LOG_FILE"
            return
        fi
        
        # Récupérer les informations de la dernière version depuis GitHub
        local github_response=$(curl -s "$UPDATE_URL" 2>> "$ERROR_LOG_FILE")
        
        if [ -z "$github_response" ]; then
            # Essayer une approche différente si l'API de release ne fonctionne pas
            print_message "yellow" "Tentative de récupération des informations depuis le dépôt principal..."
            github_response=$(curl -s "https://api.github.com/repos/$GITHUB_REPO/contents" 2>> "$ERROR_LOG_FILE")
            
            if [ -z "$github_response" ]; then
                print_message "red" "Impossible de vérifier les mises à jour du script."
                log_message "Impossible de vérifier les mises à jour du script." "$ERROR_LOG_FILE"
                return
            fi
            
            # Vérifier si le dépôt existe et est accessible
            if echo "$github_response" | grep -q "Not Found"; then
                print_message "red" "Dépôt GitHub introuvable: $GITHUB_REPO"
                log_message "Dépôt GitHub introuvable: $GITHUB_REPO" "$ERROR_LOG_FILE"
                return
            fi
            
            print_message "green" "Le dépôt MacGuardian Pro est accessible."
            print_message "yellow" "Pour mettre à jour manuellement, visitez: https://github.com/$GITHUB_REPO"
            log_message "Dépôt accessible. Mise à jour manuelle recommandée: https://github.com/$GITHUB_REPO" "$LOG_FILE"
            return
        fi
        
        # Extraire la version
        local latest_version=$(echo "$github_response" | grep -o '"tag_name": "[^"]*' | cut -d'"' -f4)
        
        if [ -z "$latest_version" ]; then
            print_message "red" "Impossible de déterminer la dernière version du script."
            log_message "Impossible de déterminer la dernière version du script." "$ERROR_LOG_FILE"
            return
        fi
        
        # Comparer les versions
        if [ "$latest_version" == "$VERSION" ]; then
            print_message "yellow" "MacGuardian Pro est à jour (version $VERSION)."
            log_message "Script à jour (version $VERSION)." "$LOG_FILE"
        else
            print_message "green" "Une nouvelle version de MacGuardian Pro est disponible : $latest_version (vous avez $VERSION)"
            log_message "Nouvelle version disponible : $latest_version" "$LOG_FILE"
            
            if confirm "Voulez-vous télécharger et installer la nouvelle version?"; then
                print_message "green" "Téléchargement de la nouvelle version en cours..."
                
                # Extraire l'URL de téléchargement
                local download_url=$(echo "$github_response" | grep -o '"browser_download_url": "[^"]*' | head -n 1 | cut -d'"' -f4)
                
                if [ -z "$download_url" ]; then
                    # Si pas d'URL directe pour le binaire, utiliser l'URL du code source
                    download_url=$(echo "$github_response" | grep -o '"zipball_url": "[^"]*' | cut -d'"' -f4)
                    
                    if [ -z "$download_url" ]; then
                        download_url=$(echo "$github_response" | grep -o '"tarball_url": "[^"]*' | cut -d'"' -f4)
                    fi
                    
                    if [ -z "$download_url" ]; then
                        download_url="https://github.com/$GITHUB_REPO/archive/refs/tags/$latest_version.zip"
                    fi
                fi
                
                if [ -z "$download_url" ]; then
                    print_message "red" "Impossible de trouver l'URL de téléchargement."
                    log_message "Impossible de trouver l'URL de téléchargement." "$ERROR_LOG_FILE"
                    print_message "yellow" "Vous pouvez télécharger manuellement la dernière version à: https://github.com/$GITHUB_REPO/releases/latest"
                    log_message "URL pour téléchargement manuel: https://github.com/$GITHUB_REPO/releases/latest" "$LOG_FILE"
                    return
                fi
                
                # Définir un dossier temporaire pour le téléchargement
                local temp_dir="/tmp/macguardian_update_$(date +%s)"
                mkdir -p "$temp_dir"
                
                if [ $? -ne 0 ]; then
                    print_message "red" "Impossible de créer le dossier temporaire pour la mise à jour."
                    log_message "Impossible de créer le dossier temporaire pour la mise à jour." "$ERROR_LOG_FILE"
                    return
                fi
                
                # Télécharger la nouvelle version
                print_message "yellow" "Téléchargement depuis: $download_url"
                local archive_file="$temp_dir/update.zip"
                curl -L "$download_url" -o "$archive_file" 2>> "$ERROR_LOG_FILE"
                
                if [ $? -ne 0 ]; then
                    print_message "red" "Erreur lors du téléchargement de la mise à jour."
                    log_message "Erreur lors du téléchargement de la mise à jour." "$ERROR_LOG_FILE"
                    rm -rf "$temp_dir"
                    return
                fi
                
                print_message "green" "Téléchargement terminé. Extraction en cours..."
                
                # Extraire l'archive
                if [[ "$download_url" == *".zip" ]]; then
                    # Vérifier si unzip est disponible
                    if ! command -v unzip &> /dev/null; then
                        print_message "red" "La commande unzip n'est pas disponible sur ce système."
                        log_message "La commande unzip n'est pas disponible." "$ERROR_LOG_FILE"
                        rm -rf "$temp_dir"
                        return
                    fi
                    
                    unzip -q "$archive_file" -d "$temp_dir" 2>> "$ERROR_LOG_FILE"
                else
                    # Vérifier si tar est disponible
                    if ! command -v tar &> /dev/null; then
                        print_message "red" "La commande tar n'est pas disponible sur ce système."
                        log_message "La commande tar n'est pas disponible." "$ERROR_LOG_FILE"
                        rm -rf "$temp_dir"
                        return
                    fi
                    
                    tar -xf "$archive_file" -C "$temp_dir" 2>> "$ERROR_LOG_FILE"
                fi
                
                if [ $? -ne 0 ]; then
                    print_message "red" "Erreur lors de l'extraction de la mise à jour."
                    log_message "Erreur lors de l'extraction de la mise à jour." "$ERROR_LOG_FILE"
                    rm -rf "$temp_dir"
                    return
                fi
                
                # Trouver le script principal dans les fichiers extraits
                local update_script=$(find "$temp_dir" -type f -name "mac_cleaner.sh" -o -name "macguardian.sh" -o -name "MacGuardian*.sh" | head -1)
                
                if [ -z "$update_script" ]; then
                    print_message "red" "Impossible de trouver le script principal dans l'archive téléchargée."
                    log_message "Impossible de trouver le script principal dans l'archive téléchargée." "$ERROR_LOG_FILE"
                    rm -rf "$temp_dir"
                    return
                fi
                
                print_message "green" "Mise à jour trouvée. Installation en cours..."
                
                # Remplacer le script actuel
                sudo cp "$update_script" "$SCRIPT_PATH" 2>> "$ERROR_LOG_FILE"
                sudo chmod +x "$SCRIPT_PATH" 2>> "$ERROR_LOG_FILE"
                
                if [ $? -eq 0 ]; then
                    print_message "green" "Mise à jour de MacGuardian Pro installée avec succès!"
                    log_message "Mise à jour du script installée avec succès." "$LOG_FILE"
                    
                    # Nettoyer le dossier temporaire
                    rm -rf "$temp_dir"
                    
                    if confirm "Voulez-vous redémarrer le script avec la nouvelle version?"; then
                        log_message "Redémarrage du script avec la nouvelle version." "$LOG_FILE"
                        exec "$SCRIPT_PATH"
                    fi
                else
                    print_message "red" "Erreur lors de l'installation de la mise à jour."
                    log_message "Erreur lors de l'installation de la mise à jour." "$ERROR_LOG_FILE"
                    rm -rf "$temp_dir"
                fi
            else
                print_message "yellow" "Installation de la mise à jour ignorée."
                log_message "Installation de la mise à jour ignorée." "$LOG_FILE"
            fi
        fi
    else
        print_message "yellow" "Vérification des mises à jour du script ignorée."
        log_message "Vérification des mises à jour du script ignorée." "$LOG_FILE"
    fi
}

# ========================================================
# Fonction principale
# ========================================================

main() {
    clear
    print_message "blue" "=========================================================="
    print_message "blue" "           MACGUARDIAN PRO - NETTOYAGE MAC               "
    print_message "blue" "                   VERSION $VERSION                       "
    print_message "blue" "=========================================================="
    print_message "yellow" "Dernière mise à jour: $CURRENT_DATE"
    print_message "yellow" "Créé par: $AUTHOR"
    print_message "yellow" "Exécuté par: $CURRENT_USER"
    print_message "yellow" "ATTENTION: Ce script va supprimer des fichiers de votre système."
    print_message "yellow" "Assurez-vous d'avoir fait une sauvegarde avant de continuer."
    echo ""
    
    # Vérifier si le script est exécuté avec les droits d'administrateur
    if [ "$EUID" -ne 0 ]; then
        print_message "red" "Ce script nécessite des droits d'administrateur."
        print_message "yellow" "Veuillez l'exécuter avec sudo: sudo $0"
        exit 1
    fi
    
    if ! confirm "Voulez-vous continuer?"; then
        print_message "red" "Opération annulée."
        exit 0
    fi
    
    # Créer les dossiers et fichiers de logs
    create_log_directories
    
    # Menu principal de nettoyage
    clean_system_cache
    clean_user_cache
    clean_temp_files
    clean_system_logs
    clean_old_downloads
    clean_ds_store
    empty_trash
    purge_time_machine_snapshots
    clean_app_caches
    flush_dns_cache
    
    # Fonctionnalités de mise à jour
    check_system_updates
    check_script_updates
    
    # Fin du script
    log_message "Fin du nettoyage" "$LOG_FILE"
    print_message "blue" "\n=========================================================="
    print_message "blue" "           MACGUARDIAN PRO - NETTOYAGE TERMINÉ           "
    print_message "blue" "=========================================================="
    print_message "green" "Le nettoyage est terminé. Les journaux ont été créés à: $LOG_FILE"
    print_message "yellow" "Il est recommandé de redémarrer votre Mac pour appliquer tous les changements."
    
    if confirm "Voulez-vous redémarrer maintenant?"; then
        print_message "green" "Redémarrage en cours..."
        sudo shutdown -r now
    else
        print_message "yellow" "N'oubliez pas de redémarrer plus tard."
    fi
    
    exit 0
}

# Exécution de la fonction principale
main
