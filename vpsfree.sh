#!/bin/bash
clear
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Auto-repair frontend locks or half-installed packages before running
echo -e "${YELLOW}Optimizing package manager environment...${NC}"
dpkg --configure -a >/dev/null 2>&1
apt-get install -f -y >/dev/null 2>&1

echo "
#######################################################################################
#
#                    LXDE + XRDP + TAILSCALE VPS INSTALLER (2026)
#
#######################################################################################"
echo "Select an option:"
echo "1) Install LXDE + XRDP + Tailscale (RDP Setup)"
echo "2) Install Basic Packages"
echo "3) Install Node.js"
read -p "Enter option: " option

if [ "$option" -eq 1 ]; then
    clear
    echo -e "${RED}Updating system repositories... Please Wait${NC}"
    apt-get update && apt-get upgrade -y
    
    echo -e "${RED}Installing LXDE Desktop Environment and XRDP...${NC}"
    apt-get install lxde -y
    apt-get install xrdp -y
    
    # Configure XRDP session profile
    echo "lxsession -s LXDE -e LXDE" >> /etc/xrdp/startwm.sh
    clear

    echo -e "${GREEN}Desktop and XRDP installation completed!${NC}"
    echo -e "${YELLOW}Select RDP Port (Default: 3389):${NC}"
    read selectedPort
    if [ -z "$selectedPort" ]; then selectedPort="3389"; fi

    sed -i "s/port=3389/port=$selectedPort/g" /etc/xrdp/xrdp.ini
    
    # --- TAILSCALE SETUP ---
    clear
    echo -e "${YELLOW}Enter your Tailscale Auth Key (tskey-auth-...):${NC}"
    read tsAuthKey

    if [ -z "$tsAuthKey" ]; then
        echo -e "${RED}No Auth Key provided. Defaulting to public RDP access...${NC}"
        systemctl restart xrdp
        clear
        echo -e "${GREEN}RDP Started on Public Port $selectedPort${NC}"
    else
        clear
        echo -e "${RED}Installing and configuring Tailscale mesh VPN...${NC}"
        curl -fsSL https://tailscale.com/install.sh | sh
        
        # Authenticate Tailscale non-interactively
        tailscale up --authkey="$tsAuthKey"
        
        # Extract the local Tailscale IPv4 address
        tailscaleIP=$(tailscale ip -4)

        # Bind XRDP exclusively to the Tailscale interface for tight security
        sed -i "s/address=0.0.0.0/address=$tailscaleIP/g" /etc/xrdp/xrdp.ini

        clear
        systemctl restart xrdp
        clear
        echo -e "${GREEN}Tailscale Connected Successfully!${NC}"
        echo -e "${GREEN}Your Tailscale Private IP is: ${YELLOW}$tailscaleIP${NC}"
        echo -e "${GREEN}RDP Secure Connection Path: ${YELLOW}$tailscaleIP:$selectedPort${NC}"
    fi

elif [ "$option" -eq 2 ]; then
    clear
    echo -e "${RED}Installing baseline utilities... Please Wait${NC}"
    apt-get update && apt-get upgrade -y
    apt-get install git curl wget sudo lsof iputils-ping -y
    clear
    echo -e "${GREEN}Basic Packages Installed!${NC}" 
    echo -e "${RED}sudo / curl / wget / git / lsof / ping${NC}"

elif [ "$option" -eq 3 ]; then
    clear
    echo "Choose a Node.js version to install:"
    echo "1. 14.x"
    echo "2. 16.x"
    echo "3. 18.x"
    echo "4. 20.x"
    echo "5. 22.x"
    read -p "Enter your choice (1-5): " choice

    case $choice in
        1) version="14" ;;
        2) version="16" ;;
        3) version="18" ;;
        4) version="20" ;;
        5) version="22" ;;
        *)
            echo -e "${RED}Invalid choice. Exiting.${NC}"
            exit 1
            ;;
    esac
    clear
    echo -e "${RED}Downloading NodeSource binaries... Please Wait${NC}"
    apt-get remove --purge node* nodejs npm -y
    apt-get update && apt-get install curl -y
    curl -sL "https://deb.nodesource.com/setup_${version}.x" -o /tmp/nodesource_setup.sh
    bash /tmp/nodesource_setup.sh
    apt-get install -y nodejs
    clear
    echo -e "${GREEN}Node.js version $version has been successfully installed.${NC}"

else
    echo -e "${RED}Invalid option selected.${NC}"
fi
