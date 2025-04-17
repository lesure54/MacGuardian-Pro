#!/bin/bash

# Méta-informations
readonly VERSION="3.0"
readonly CURRENT_DATE="2025-04-17 09:42:48"
readonly CURRENT_USER="rikasa288"

# Import des fonctions communes
source "$(dirname "$0")/../utils/common.sh"

# Fonction de nettoyage des applications
clean_applications() {
    log "INFO" "Démarrage du nettoyage des applications..."
    
    # Liste des applications à nettoyer (peut être configurée)
    local apps_to_clean=($(find /Applications -maxdepth 1 -name "*.app"))
    
    for app in "${apps_to_clean[@]}"; do
        if [[ -d "$app" ]]; then
            local app_name=$(basename "$app" .app)
            log "INFO" "Analyse de $app_name..."
            
            # Suppression des fichiers associés
            find ~/Library/Application\ Support -name "*$app_name*" -exec rm -rf {} \; 2>/dev/null
            find ~/Library/Caches -name "*$app_name*" -exec rm -rf {} \; 2>/dev/null
            find ~/Library/Preferences -name "*$app_name*" -exec rm -rf {} \; 2>/dev/null
        fi
    done
}

# Fonction de gestion du PATH
manage_path() {
    log "INFO" "Vérification du PATH..."
    
    # Sauvegarde du PATH original
    local original_path=$PATH
    local path_entries=($(echo $PATH | tr ':' '\n'))
    local unique_entries=()
    
    # Suppression des doublons et entrées invalides
    for entry in "${path_entries[@]}"; do
        if [[ -d "$entry" ]] && [[ ! " ${unique_entries[@]} " =~ " ${entry} " ]]; then
            unique_entries+=("$entry")
        fi
    done
    
    # Reconstruction du PATH
    export PATH=$(IFS=:; echo "${unique_entries[*]}")
    log "SUCCESS" "PATH optimisé"
}

# Fonction de nettoyage des caches
clean_caches() {
    log "INFO" "Nettoyage des caches système..."
    
    # Liste des dossiers de cache à nettoyer
    local cache_dirs=(
        ~/Library/Caches
        /Library/Caches
        ~/Library/Logs
        /Library/Logs
    )
    
    for dir in "${cache_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            du -sh "$dir" 2>/dev/null | awk '{print $1}' | while read size; do
                log "INFO" "Nettoyage de $dir (Taille: $size)"
            done
            sudo rm -rf "$dir"/* 2>/dev/null
        fi
    done
}

# Gestion des éléments de démarrage
manage_startup_items() {
    log "INFO" "Gestion des éléments de démarrage..."
    
    local launch_agents=(
        ~/Library/LaunchAgents
        /Library/LaunchAgents
        /System/Library/LaunchAgents
    )
    
    for dir in "${launch_agents[@]}"; do
        if [[ -d "$dir" ]]; then
            log "INFO" "Analyse de $dir"
            find "$dir" -name "*.plist" -exec plutil -p {} \; | grep Label
        fi
    done
}

# Optimisation système
optimize_system() {
    log "INFO" "Application des optimisations système..."
    
    # Optimisations diverses
    sudo defaults write NSGlobalDomain NSWindowResizeTime .001
    sudo defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
    sudo defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
    sudo defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
    
    # Optimisation Finder
    defaults write com.apple.finder QuitMenuItem -bool true
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    
    log "SUCCESS" "Optimisations système appliquées"
}

# Optimisation réseau
optimize_network() {
    log "INFO" "Optimisation des paramètres réseau..."
    
    # Flush DNS cache
    sudo dscacheutil -flushcache
    sudo killall -HUP mDNSResponder
    
    # Optimisation DNS
    networksetup -setdnsservers Wi-Fi 8.8.8.8 8.8.4.4
    
    # Autres optimisations réseau
    sudo sysctl -w net.inet.tcp.delayed_ack=0
    
    log "SUCCESS" "Paramètres réseau optimisés"
}

# Optimisation batterie
optimize_battery() {
    log "INFO" "Application des optimisations batterie..."
    
    # Vérification si c'est un MacBook
    if system_profiler SPPowerDataType | grep -q "Battery"; then
        # Optimisations batterie
        sudo pmset -a hibernatemode 3
        sudo pmset -a standby 1
        sudo pmset -a powernap 0
        sudo pmset -a lidwake 1
        
        log "SUCCESS" "Optimisations batterie appliquées"
    else
        log "INFO" "Pas de batterie détectée - Skip"
    fi
}

# Audit sécurité
security_audit() {
    log "INFO" "Démarrage de l'audit de sécurité..."
    
    # Vérification FileVault
    if ! fdesetup status | grep -q "On"; then
        log "WARNING" "FileVault est désactivé"
    fi
    
    # Vérification Firewall
    if ! sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate | grep -q "enabled"; then
        log "WARNING" "Pare-feu est désactivé"
    fi
    
    # Vérification SIP
    if ! csrutil status | grep -q "enabled"; then
        log "WARNING" "Protection de l'intégrité du système (SIP) est désactivée"
    fi
    
    log "SUCCESS" "Audit de sécurité terminé"
}

# Nettoyage dossiers cachés
clean_hidden_folders() {
    log "INFO" "Analyse des dossiers cachés..."
    
    # Liste des dossiers cachés connus
    local hidden_dirs=(
        ~/.Trash
        ~/Library/Application\ Support
        ~/Library/Containers
        ~/Library/Group\ Containers
    )
    
    for dir in "${hidden_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            du -sh "$dir" 2>/dev/null | awk '{print $1}' | while read size; do
                log "INFO" "Dossier $dir : $size"
            done
        fi
    done
}

# Génération de rapport HTML avec graphiques
generate_interactive_report() {
    local report_file="$REPORT_DIR/system_report_$(date +%Y%m%d_%H%M%S).html"
    
    cat > "$report_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Rapport Système - $(date '+%Y-%m-%d')</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; margin: 20px; }
        .container { max-width: 1200px; margin: 0 auto; }
        .chart-container { margin: 20px 0; padding: 20px; border: 1px solid #eee; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Rapport Système MacGuardian Pro</h1>
        <p>Date: $CURRENT_DATE</p>
        <p>Utilisateur: $CURRENT_USER</p>
        
        <div class="chart-container">
            <canvas id="diskUsageChart"></canvas>
        </div>
        
        <div class="chart-container">
            <canvas id="startupItemsChart"></canvas>
        </div>
    </div>
    
    <script>
        // Données d'utilisation du disque
        const diskData = {
            labels: ['Système', 'Applications', 'Documents', 'Autre'],
            datasets: [{
                data: [
                    $(df -h / | awk 'NR==2 {print $3}' | sed 's/Gi//'),
                    $(du -sh /Applications 2>/dev/null | cut -f1),
                    $(du -sh ~/Documents 2>/dev/null | cut -f1),
                    $(df -h / | awk 'NR==2 {print $4}' | sed 's/Gi//')
                ],
                backgroundColor: ['#FF6384', '#36A2EB', '#FFCE56', '#4BC0C0']
            }]
        };
        
        // Création des graphiques
        new Chart(document.getElementById('diskUsageChart'), {
            type: 'pie',
            data: diskData,
            options: {
                responsive: true,
                plugins: {
                    title: {
                        display: true,
                        text: 'Utilisation du disque'
                    }
                }
            }
        });
    </script>
</body>
</html>
EOF

    log "SUCCESS" "Rapport généré : $report_file"
}

# Menu principal
show_optimization_menu() {
    while true; do
        echo -e "\n${COLORS[HEADER]}=== Menu d'Optimisation ===${COLORS[RESET]}"
        echo "1. Nettoyage applications"
        echo "2. Gestion PATH"
        echo "3. Nettoyage caches"
        echo "4. Gestion démarrage"
        echo "5. Optimisation système"
        echo "6. Optimisation réseau"
        echo "7. Optimisation batterie"
        echo "8. Audit sécurité"
        echo "9. Nettoyage dossiers cachés"
        echo "10. Générer rapport"
        echo "11. Retour"
        
        read -p "Choix : " choice
        
        case $choice in
            1) clean_applications ;;
            2) manage_path ;;
            3) clean_caches ;;
            4) manage_startup_items ;;
            5) optimize_system ;;
            6) optimize_network ;;
            7) optimize_battery ;;
            8) security_audit ;;
            9) clean_hidden_folders ;;
            10) generate_interactive_report ;;
            11) return ;;
            *) log "ERROR" "Choix invalide" ;;
        esac
    done
}

# Point d'entrée principal
main() {
    log "INFO" "Module d'optimisation système démarré"
    show_optimization_menu
}

# Exécution
main
