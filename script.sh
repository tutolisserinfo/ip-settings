#!/bin/bash

# Vérification des permissions root
if [ "$EUID" -ne 0 ]; then
    echo "Veuillez exécuter ce script en tant que root (sudo)."
    exit 1
fi

# Chemin vers le fichier interfaces
INTERFACES_FILE="/etc/network/interfaces"

# Sauvegarde du fichier actuel
backup_file() {
    cp "$INTERFACES_FILE" "${INTERFACES_FILE}.bak_$(date +%Y%m%d%H%M%S)"
    echo "Sauvegarde créée : ${INTERFACES_FILE}.bak"
}

# Configuration d'une adresse IP statique
configure_static_ip() {
    read -p "Entrez le nom de l'interface réseau (par exemple, enp0s3) : " interface
    read -p "Entrez l'adresse IP (par exemple, 192.168.15.50/24) : " ip_address
    read -p "Entrez la passerelle (par exemple, 192.168.15.1) : " gateway

    echo "Souhaitez-vous configurer les paramètres DNS ? (y/n)"
    read -p "Réponse : " configure_dns

    if [[ "$configure_dns" == "y" || "$configure_dns" == "Y" ]]; then
        read -p "Entrez les serveurs DNS séparés par des espaces (par exemple, 192.168.15.100 1.1.1.1) : " dns
        read -p "Entrez le domaine DNS (par exemple, cleanergyo.local) : " dns_domain
    else
        dns=""
        dns_domain=""
    fi

    # Sauvegarde et modification
    backup_file

    # Supprimer la configuration existante pour l'interface
    sed -i "/^auto $interface\$/,/^$/d" "$INTERFACES_FILE"

    # Ajouter la nouvelle configuration
    {
        echo "auto $interface"
        echo "iface $interface inet static"
        echo "    address $ip_address"
        echo "    gateway $gateway"
        if [[ -n "$dns" ]]; then
            echo "    dns-nameservers $dns"
        fi
        if [[ -n "$dns_domain" ]]; then
            echo "    dns-domain $dns_domain"
        fi
    } >> "$INTERFACES_FILE"

    echo "Configuration IP statique appliquée dans $INTERFACES_FILE."
    echo "Redémarrage requis pour appliquer les modifications."
}

# Configuration DHCP
configure_dhcp_ip() {
    read -p "Entrez le nom de l'interface réseau (par exemple, enp0s3) : " interface

    echo "Souhaitez-vous configurer les paramètres DNS ? (y/n)"
    read -p "Réponse : " configure_dns

    if [[ "$configure_dns" == "y" || "$configure_dns" == "Y" ]]; then
        read -p "Entrez les serveurs DNS séparés par des espaces (par exemple, 192.168.15.100 1.1.1.1) : " dns
        read -p "Entrez le domaine DNS (par exemple, cleanergyo.local) : " dns_domain
    else
        dns=""
        dns_domain=""
    fi

    # Sauvegarde et modification
    backup_file

    # Supprimer la configuration existante pour l'interface
    sed -i "/^auto $interface\$/,/^$/d" "$INTERFACES_FILE"

    # Ajouter la configuration DHCP
    {
        echo "auto $interface"
        echo "iface $interface inet dhcp"
        if [[ -n "$dns" ]]; then
            echo "    dns-nameservers $dns"
        fi
        if [[ -n "$dns_domain" ]]; then
            echo "    dns-domain $dns_domain"
        fi
    } >> "$INTERFACES_FILE"

    echo "Configuration DHCP appliquée dans $INTERFACES_FILE."
    echo "Redémarrage requis pour appliquer les modifications."
}

# Menu principal
echo "Configuration de l'adresse IP via /etc/network/interfaces"
echo "1) Configurer une adresse IP statique"
echo "2) Configurer une adresse IP en DHCP"
echo "3) Quitter"

read -p "Entrez votre choix (1/2/3) : " choice

case $choice in
    1)
        configure_static_ip
        ;;
    2)
        configure_dhcp_ip
        ;;
    3)
        echo "Abandon de la configuration."
        exit 0
        ;;
    *)
        echo "Choix invalide. Veuillez relancer le script."
        exit 1
        ;;
esac

echo "Pour appliquer les modifications, redémarrez le réseau avec :"
echo "  sudo systemctl restart networking"
