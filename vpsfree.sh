#!/bin/bash
clear
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "
#######################################################################################
#
#                                  VPSFREE.ES SCRIPTS
#
#                           Copyright (C) 2022 - 2023, VPSFREE.ES
#
#######################################################################################"
echo "Select an option:"
echo "1) LXDE - XRDP (Tailscale Optimized)"
echo "2) PufferPanel"
echo "3) Install Basic Packages"
echo "4) Install Nodejs"
read -p "Enter choice [1-4]: " option < /dev/tty

if [ "$option" -eq 1 ]; then
    clear
    echo -e "${RED}Checking and installing Tailscale first...${NC}"
    
    # Install Tailscale if not present
    if ! command -v tailscale &> /dev/null; then
        curl -fsSL https://tailscale.com/install.sh | sh
    else
        echo -e "${GREEN}Tailscale is already installed.${NC}"
    fi

    echo -e "${YELLOW}Starting Tailscale background service...${NC}"
    # Ensure tailscaled daemon is actually running (especially inside containers)
    if command -v systemctl &> /dev/null; then
        systemctl start tailscaled
        sleep 2
    else
        # Userspace fallback if systemctl isn't functional or available
        tailscaled --tun=userspace-networking --socks5-server=localhost:1055 --outbound-http-proxy-listen=localhost:1055 &
        sleep 3
    fi

    # Authenticate Tailscale (Automated vs Manual Link fallback)
    if [ -n "$TS_KEY" ]; then
        echo -e "${GREEN}Auth key detected. Authenticating silently...${NC}"
        tailscale up --authkey="$TS_KEY"
    else
        echo -e "${YELLOW}No TS_KEY variable found. Please authenticate manually using this link:${NC}"
        tailscale up
    fi

    # Fetch Tailscale IP
    TS_IP=$(tailscale ip -4)
    if [ -z "$TS_IP" ]; then
        echo -e "${RED}Failed to get Tailscale IP. Defaulting to localhost (127.0.0.1)${NC}"
        TS_IP="127.0.0.1"
    else
        echo -e "${GREEN}Tailscale IP detected: $TS_IP${NC}"
    fi

    echo -e "${RED}Downloading LXDE & XRDP... Please Wait${NC}"
    apt update && apt upgrade -y
    export SUDO_FORCE_REMOVE=yes
    apt remove sudo -y
    apt install lxde -y
    apt install xrdp -y
    
    # Configure XRDP session for LXDE
    echo "lxsession -s LXDE -e LXDE" >> /etc/xrdp/startwm.sh
    
    clear
    echo -e "${GREEN}Downloading and installation completed!${NC}"
    echo -e "${YELLOW}Select RDP Port (Default: 3389)${NC}"
    read selectedPort < /dev/tty
    if [ -z "$selectedPort" ]; then selectedPort="3389"; fi

    # Secure XRDP: Bind it strictly to your Tailscale IP
    sed -i "s/port=3389/port=$TS_IP:$selectedPort/g" /etc/xrdp/xrdp.ini

    service xrdp restart
    clear
    echo -e "${GREEN}RDP Created and secured over Tailscale!${NC}"
    echo -e "${YELLOW}Connect using your RDP client to:${NC}"
    echo -e "${GREEN}$TS_IP:$selectedPort${NC}"

elif [ "$option" -eq 2 ]; then
    clear
    echo -e "${RED}Downloading... Please Wait${NC}"
    apt update && apt upgrade -y
    export SUDO_FORCE_REMOVE=yes
    apt remove sudo -y
    apt install curl wget git python3 -y
    curl -s https://packagecloud.io/install/repositories/pufferpanel/pufferpanel/script.deb.sh | bash
    apt update && apt upgrade -y
    curl -o /bin/systemctl https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl3.py
    chmod -R 777 /bin/systemctl
    apt install pufferpanel -y
    clear
    echo -e "${GREEN}PufferPanel installation completed!${NC}"
    echo -e "${YELLOW}Enter PufferPanel Port${NC}"
    read pufferPanelPort < /dev/tty

    sed -i "s/\"host\": \"0.0.0.0:8080\"/\"host\": \"0.0.0.0:$pufferPanelPort\"/g" /etc/pufferpanel/config.json
    echo -e "${YELLOW}Enter the username for the admin user:${NC}"
    read adminUsername < /dev/tty
    echo -e "${YELLOW}Enter the password for the admin user:${NC}"
    read adminPassword < /dev/tty
    echo -e "${YELLOW}Enter the email for the admin user:${NC}"
    read adminEmail < /dev/tty

    pufferpanel user add --name "$adminUsername" --password "$adminPassword" --email "$adminEmail" --admin
    clear
    echo -e "${GREEN}Admin user $adminUsername added successfully!${NC}"
    systemctl restart pufferpanel
    clear
    echo -e "${GREEN}PufferPanel Created & Started - PORT: $pufferPanelPort${NC}"

elif [ "$option" -eq 3 ]; then
    clear
    echo -e "${RED}Downloading... Please Wait${NC}"
    apt update && apt upgrade -y
    apt install git curl wget sudo lsof iputils-ping -y
    curl -o /bin/systemctl https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl3.py
    chmod -R 777 /bin/systemctl
    clear
    echo -e "${GREEN}Basic Packages Installed!${NC}" 
    echo -e "${RED}sudo / curl / wget / git / lsof / ping${NC}"

elif [ "$option" -eq 4 ]; then
    clear
    echo "Choose a Node.js version to install:"
    echo "1. 12.x"
    echo "2. 13.x"
    echo "3. 14.x"
    echo "4. 15.x"
    echo "5. 16.x"
    echo "6. 17.x"
    echo "7. 18.x"
    echo "8. 19.x"
    echo "9. 20.x"

    read -p "Enter your choice (1-9): " choice < /dev/tty

    case $choice in
        1) version="12" ;;
        2) version="13" ;;
        3) version="14" ;;
        4) version="15" ;;
        5) version="16" ;;
        6) version="17" ;;
        7) version="18" ;;
        8) version="19" ;;
        9) version="20" ;;
        *)
            echo -e "${RED}Invalid choice. Exiting.${NC}"
            exit 1
            ;;
    esac
    echo -e "${RED}Downloading... Please Wait${NC}"
    apt remove --purge node* nodejs npm -y
    apt update && apt upgrade -y && apt install curl -y
    curl -sL "https://deb.nodesource.com/setup_${version}.x" -o /tmp/nodesource_setup.sh
    bash /tmp/nodesource_setup.sh
    apt update -y
    apt install -y nodejs
    clear
    echo -e "${GREEN}Node.js version $version has been installed.${NC}"

else
    echo -e "${RED}Invalid option selected.${NC}"
fi
