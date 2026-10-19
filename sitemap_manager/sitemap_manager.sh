#!/bin/bash

# ==============================================================================
# Nom du script : sitemap-manager.sh
# Description : Utilitaire DevOps pour gérer et mettre à jour le sitemap.xml
# ==============================================================================

# Fonction interne : Vérification de la présence du sitemap
check_sitemap_env() {
    if [ -f "sitemap.xml" ]; then
        return 0
    else
        echo "❌ Erreur : Aucun fichier sitemap.xml détecté dans le répertoire courant."
        return 1
    fi
}

# Fonction publique : Aide de l'utilitaire
sitemap_help() {
    echo "=== Aide : Sitemap Manager ==="
    echo "Cet utilitaire permet de gérer le fichier sitemap.xml d'un site web."
    echo "Il gère actuellement :"
    echo "  - La mise à jour interactive des balises <lastmod> (contenu)."
    echo "  - Une navigation en boucle pour enchaîner les opérations."
    echo ""
    echo "Utilisation :"
    echo "  sitemap_manager        Lance le menu interactif."
    echo "  sitemap_help           Affiche cette aide."
}

# ==============================================================================
# FONCTION DÉDIÉE : Écriture / Mise à jour du lastmod dans le fichier XML
# Retourne 0 si la modification a réussi, 1 si elle a échoué ou n'a rien trouvé.
# ==============================================================================
update_xml_lastmod() {
    local target_url="$1"
    local new_date="$2"

    # Nettoyage de l'URL pour supprimer tout résidu de retour chariot Windows (\r)
    target_url=$(echo "$target_url" | tr -d '\r')

    # Utilisation d'awk avec un indicateur de changement (changed)
    if awk -v target="$target_url" -v newdate="$new_date" '
    BEGIN { found = 0; changed = 0 }
    {
        sub(/\r$/, "");

        if (index($0, "<loc>" target "</loc>")) {
            found = 1;
        } else if (found && index($0, "<lastmod>")) {
            sub(/<lastmod>[^<]*<\/lastmod>/, "<lastmod>" newdate "</lastmod>");
            found = 0;
            changed = 1;
        }
        print
    }
    END { exit (changed ? 0 : 1) }
    ' sitemap.xml > sitemap.xml.tmp; then
        # Si awk a bien trouvé et modifié la ligne, on écrase le sitemap original
        mv sitemap.xml.tmp sitemap.xml
        return 0
    else
        # Sinon, on nettoie le fichier temporaire et on retourne une erreur
        rm -f sitemap.xml.tmp
        return 1
    fi
}

# Fonction interne : Mise à jour interactive du contenu (lastmod)
update_content_lastmod() {
    echo ""
    echo "=== 🔄 Mise à jour du contenu (lastmod) ==="
    
    current_date=$(date +%Y-%m-%d)
    echo "📅 Date qui sera appliquée : $current_date"
    echo "------------------------------------------------------------------"

    # Extraction des URLs et nettoyage propre des retours chariots
    local urls
    urls=$(grep -o '<loc>[^<]*</loc>' sitemap.xml | sed 's/<loc>\(.*\)<\/loc>/\1/' | tr -d '\r')

    if [ -z "$urls" ]; then
        echo "❌ Aucune URL trouvée dans le sitemap.xml."
        return 1
    fi

    # Boucle sur chaque URL trouvée pour demander si on met à jour
    while IFS= read -r url; do
        [ -z "$url" ] && continue
        
        echo ""
        echo "🔗 Page détectée : $url"
        read -p "Souhaitez-vous mettre à jour la date de modification de cette page ? (o/N) : " response < /dev/tty
        
        if [[ "$response" =~ ^([oO][uU][iI]|[oO])$ ]]; then
            # Appel de la fonction dédiée et test de son retour (vrai/faux)
            if update_xml_lastmod "$url" "$current_date"; then
                echo "✅ [Succès] La balise <lastmod> pour cette URL a été mise à jour au $current_date."
            else
                echo "❌ [Erreur] La balise <lastmod> n'a pas pu être trouvée ou mise à jour pour cette URL."
            fi
        else
            echo "⏭️  Ignoré."
        fi
    done <<< "$urls"

    echo "------------------------------------------------------------------"
    echo "✨ Fin du parcours des pages."
}

# Fonction publique maîtresse (Point d'entrée principal)
sitemap_manager() {
    # Étape 1 : Vérification de l'environnement
    if ! check_sitemap_env; then
        return 1
    fi

    # Étape 2 : Boucle principale pour enchaîner les actions
    while true; do
        echo ""
        echo "=========================================================="
        echo "🚀 UTILITAIRE SITEMAP MANAGER - Menu Principal"
        echo "=========================================================="
        echo "1) Mettre à jour le contenu (Parcours des <lastmod>)"
        echo "2) Ajouter une page (Bientôt disponible)"
        echo "3) Modifier une URL (Bientôt disponible)"
        echo "4) Quitter"
        echo ""
        
        read -p "Votre choix [1-4] : " choice
        
        case $choice in
            1)
                update_content_lastmod
                ;;
            2)
                echo "🚧 Fonctionnalité d'ajout de page en cours de conception."
                ;;
            3)
                echo "🚧 Fonctionnalité de modification d'URL en cours de conception."
                ;;
            4)
                echo "👋 Fermeture de Sitemap Manager. À bientôt !"
                break
                ;;
            *)
                echo "❌ Choix invalide. Veuillez entrer un nombre entre 1 et 4."
                ;;
        esac
    done
}