#!/bin/bash
clear

# Color definitions
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' 

echo -e "${YELLOW}"
echo "#######################################################################################"
echo "#                                                                                     #"
echo "#                                  VPSFREE.ES SCRIPTS                                 #"
echo "#                                                                                     #"
echo "#                           Copyright (C) 2022 - 2023, VPSFREE.ES                     #"
echo "#                                                                                     #"
echo "#######################################################################################"
echo -e "${NC}"

echo "Select an option:"
echo "1) LXDE - XRDP (No Black Screen + Pinggy)"
echo "2) PufferPanel (with Pinggy Option)"
echo "3) Install Basic Packages"
echo "4) Install Nodejs"
read -p "Enter option (1-4): " option

# Input validation to prevent bash expression errors
if [[ -z "$option" || ! "$option" =~ ^[1-4]$ ]]; then
    echo -e "${RED}Error: Invalid option selected. Please enter a number from 1 to 4.${NC}"
    exit 1
fi

if [ "$option" -eq 1 ]; then
    clear
    echo -e "${RED}Downloading LXDE & XRDP... Please Wait${NC}"
    apt update && apt upgrade -y
    apt install lxde lxtask lxterminal -y
    apt install xrdp -y
    
    # --- FIX BLACK SCREEN ---
    # Configure global and user-level desktop initializers cleanly
    echo "lxsession -s LXDE -e LXDE" > ~/.xsession
    echo "export STARTUP=\"lxsession -s LXDE -e LXDE\"" > ~/.xsessionrc
    
    # Fix the main startwm.sh script to execute LXDE properly
    sed -i 's/test -x \/etc\/X11\/Xsession && exec \/etc\/X11\/Xsession/#test -x \/etc\/X11\/Xsession \&\& exec \/etc\/X11\/Xsession/g' /etc/xrdp/startwm.sh
    sed -i 's/exec \/bin\/sh \/etc\/X11\/Xsession/#exec \/bin\/sh \/etc\/X11\/Xsession/g' /etc/xrdp/startwm.sh
    echo "lxsession -s LXDE -e LXDE" >> /etc/xrdp/startwm.sh

    clear
    echo -e "${GREEN}Installation completed!${NC}"
    echo -e "${YELLOW}Select RDP Port (Default: 3389):${NC}"
    read selectedPort
    if [ -z "$selectedPort" ]; then selectedPort="3389"; fi

    sed -i "s/port=3389/port=$selectedPort/g" /etc/xrdp/xrdp.ini
    
    clear
    systemctl restart xrdp || service xrdp restart
    clear
    
    echo -e "${GREEN}RDP Created And Started locally on Port $selectedPort${NC}"
    echo -e "${YELLOW}Starting Pinggy Tunnel... Share the URL below to log in!${NC}"
    echo "--------------------------------------------------------"
    # Launch Pinggy tunnel dynamically
    ssh -p 443 -R0.0.0.0:22:localhost:$selectedPort a.pinggy.io

elif [ "$option" -eq 2 ]; then
    clear
    echo -e "${RED}Downloading PufferPanel... Please Wait${NC}"
    apt update && apt upgrade -y
    apt install curl wget git python3 sudo -y
    curl -s https://packagecloud.io/install/repositories/pufferpanel/pufferpanel/script.deb.sh | bash
    apt update && apt upgrade -y
    
    # Handle environment types without systemd
    if [ ! -d /run/systemd/system ]; then
        curl -o /bin/systemctl https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl3.py
        chmod -R 777 /bin/systemctl
    fi
    
    apt install pufferpanel -y
    clear
    echo -e "${GREEN}PufferPanel installation completed!${NC}"
    echo -e "${YELLOW}Enter PufferPanel Port (Default: 8080):${NC}"
    read pufferPanelPort
    if [ -z "$pufferPanelPort" ]; then pufferPanelPort="8080"; fi

    sed -i "s/\"host\": \"0.0.0.0:8080\"/\"host\": \"0.0.0.0:$pufferPanelPort\"/g" /etc/pufferpanel/config.json
    echo -e "${YELLOW}Enter the username for the admin user:${NC}"
    read adminUsername
    echo -e "${YELLOW}Enter the password for the admin user:${NC}"
    read adminPassword
    echo -e "${YELLOW}Enter the email for the admin user:${NC}"
    read adminEmail

    pufferpanel user add --name "$adminUsername" --password "$adminPassword" --email "$adminEmail" --admin
    clear
    echo -e "${GREEN}Admin user $adminUsername added successfully!${NC}"
    systemctl restart pufferpanel || service pufferpanel restart
    clear
    echo -e "${GREEN}PufferPanel Started - PORT: $pufferPanelPort${NC}"
    echo -e "${YELLOW}Starting Pinggy Tunnel for PufferPanel Web UI...${NC}"
    echo "--------------------------------------------------------"
    ssh -p 443 -R0.0.0.0:80:localhost:$pufferPanelPort a.pinggy.io

elif [ "$option" -eq 3 ]; then
    clear
    echo -e "${RED}Downloading Basic Packages... Please Wait${NC}"
    apt update && apt upgrade -y
    apt install git curl wget sudo lsof iputils-ping openssh-client -y
    clear
    echo -e "${GREEN}Basic Packages Installed!${NC}" 
    echo -e "${RED}sudo / curl / wget / git / lsof / ping / openssh-client${NC}"

elif [ "$option" -eq 4 ]; then
    clear
    echo "Choose a Node.js version to install:"
    echo "1. 18.x (LTS Legacy)"
    echo "2. 20.x (LTS Recommended)"
    echo "3. 22.x (Current LTS)"
    echo "4. 24.x (Latest Stability)"

    read -p "Enter your choice (1-4): " choice

    if [[ -z "$choice" || ! "$choice" =~ ^[1-4]$ ]]; then
        echo -e "${RED}Invalid choice. Exiting.${NC}"
        exit 1
    fi

    case $choice in
        1) version="18" ;;
        2) version="20" ;;
        3) version="22" ;;
        4) version="24" ;;
    esac

    clear
    echo -e "${RED}Downloading Node.js v${version}... Please Wait${NC}"
    apt remove --purge node* nodejs npm -y --allow-change-held-packages
    apt update && apt upgrade -y && apt install curl gpg -y
    
    # Modern secure NodeSource distribution format
    curl -fsSL "https://deb.nodesource.com/setup_${version}.x" | bash -
    apt install -y nodejs
    clear
    echo -e "${GREEN}Node.js version $(node -v) has been successfully installed.${NC}"
fi
