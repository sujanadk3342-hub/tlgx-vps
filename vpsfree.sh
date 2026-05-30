#!/bin/bash

clear

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

install_tailscale() {
echo -e "${YELLOW}Installing Tailscale...${NC}"

```
curl -fsSL https://tailscale.com/install.sh | sh

if [ -n "$TS_KEY" ]; then
    tailscale up --authkey="$TS_KEY" --ssh --accept-routes
else
    echo -e "${RED}TS_KEY not provided!${NC}"
    echo "Export TS_KEY before running the script."
    exit 1
fi
```

}

clear

echo "
#######################################################################################

#

# LXDE + XRDP + TAILSCALE INSTALLER

#

#######################################################################################
"

echo "1) Install LXDE + XRDP + Tailscale"
echo "2) Install Basic Packages"

read -p "Select option: " option

if [ "$option" -eq 1 ]; then

```
clear
echo -e "${RED}Updating system...${NC}"

apt update -y
apt upgrade -y

apt install -y \
    curl \
    wget \
    sudo \
    git \
    lsof \
    iputils-ping

install_tailscale

echo -e "${YELLOW}Installing LXDE Desktop...${NC}"
apt install -y lxde

echo -e "${YELLOW}Installing XRDP...${NC}"
apt install -y xrdp

grep -q "lxsession -s LXDE -e LXDE" /etc/xrdp/startwm.sh || \
echo "lxsession -s LXDE -e LXDE" >> /etc/xrdp/startwm.sh

echo
read -p "Choose XRDP Port (Default 3389): " selectedPort

if [ -z "$selectedPort" ]; then
    selectedPort=3389
fi

sed -i "s/^port=.*/port=$selectedPort/" /etc/xrdp/xrdp.ini

systemctl enable xrdp
systemctl restart xrdp

TS_IP=$(tailscale ip -4 | head -n1)

clear

echo -e "${GREEN}Installation Complete!${NC}"
echo
echo "Tailscale IP : $TS_IP"
echo "RDP Port     : $selectedPort"
echo
echo "Connect from Remote Desktop using:"
echo
echo "$TS_IP:$selectedPort"
echo
```

elif [ "$option" -eq 2 ]; then

```
apt update -y
apt upgrade -y

apt install -y \
    curl \
    wget \
    sudo \
    git \
    lsof \
    iputils-ping

echo -e "${GREEN}Basic Packages Installed!${NC}"
```

else

```
echo -e "${RED}Invalid option selected.${NC}"
```

fi
