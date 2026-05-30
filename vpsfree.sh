#!/bin/bash

clear

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "
#######################################################################################

#

# LXDE + XRDP + TAILSCALE VPS INSTALLER (2026 EDITION)

#

#######################################################################################
"

echo "Select an option:"
echo "1) Install LXDE + XRDP + Tailscale (RDP Setup)"
echo "2) Install Basic Packages"
echo "3) Install Node.js"

read -p "Enter option: " option

install_tailscale() {
echo -e "${YELLOW}Installing Tailscale...${NC}"
curl -fsSL https://tailscale.com/install.sh | sh

```
echo
echo -e "${YELLOW}Enter your Tailscale Auth Key:${NC}"
read -s TS_KEY
echo

if [ -z "$TS_KEY" ]; then
    echo -e "${RED}No TS_KEY provided. Exiting.${NC}"
    exit 1
fi

tailscale up --authkey="$TS_KEY" --ssh --accept-routes

echo -e "${GREEN}Tailscale connected successfully!${NC}"
```

}

if [ "$option" -eq 1 ]; then

```
clear
echo -e "${YELLOW}Updating system...${NC}"

apt update -y && apt upgrade -y

apt install -y curl wget git sudo lsof iputils-ping

install_tailscale

echo -e "${YELLOW}Installing LXDE Desktop...${NC}"
apt install -y lxde

echo -e "${YELLOW}Installing XRDP...${NC}"
apt install -y xrdp

echo "lxsession -s LXDE -e LXDE" >> /etc/xrdp/startwm.sh

read -p "Enter RDP Port (default 3389): " RDP_PORT
RDP_PORT=${RDP_PORT:-3389}

sed -i "s/^port=.*/port=$RDP_PORT/" /etc/xrdp/xrdp.ini

systemctl enable xrdp
systemctl restart xrdp

TS_IP=$(tailscale ip -4 | head -n1)

clear
echo -e "${GREEN}====================================${NC}"
echo -e "${GREEN}        INSTALLATION COMPLETE       ${NC}"
echo -e "${GREEN}====================================${NC}"
echo
echo "Tailscale IP : $TS_IP"
echo "RDP Port     : $RDP_PORT"
echo
echo "Connect using:"
echo "$TS_IP:$RDP_PORT"
echo
```

elif [ "$option" -eq 2 ]; then

```
apt update -y && apt upgrade -y

apt install -y git curl wget sudo lsof iputils-ping

echo -e "${GREEN}Basic packages installed!${NC}"
```

elif [ "$option" -eq 3 ]; then

```
echo "Choose Node.js version:"
echo "1) 16.x"
echo "2) 18.x"
echo "3) 20.x"

read -p "Choice: " c

case $c in
    1) version=16 ;;
    2) version=18 ;;
    3) version=20 ;;
    *) echo "Invalid"; exit 1 ;;
esac

apt remove -y nodejs npm
apt update -y

curl -fsSL https://deb.nodesource.com/setup_${version}.x | bash -

apt install -y nodejs

echo -e "${GREEN}Node.js $version installed successfully!${NC}"
```

else
echo -e "${RED}Invalid option!${NC}"
fi
