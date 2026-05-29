#!/bin/bash

# --- Custom Environment Variables ---
# Change these to make it completely your own
MY_USER="devnexus"
MY_PASS="Skyline99x"
CHROME_REMOTE="false" # Set to true if you ever want Chrome instead of standard RDP

echo "========================================="
echo "   Initializing Unique Sandbox Matrix    "
echo "========================================="

# 1. Update and install base essentials quietly
sudo apt-get update -y
sudo apt-get install -y wget curl gnupg2 apt-transport-https sudo

# 2. Add Tailscale Repository securely
sudo mkdir -p /usr/share/keyrings
curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.noenv.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg > /dev/null
curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.tailscale-keyring.repo | sudo tee /etc/apt/sources.list.d/tailscale.list

# 3. Install Desktop Environment, RDP Server, and Tailscale
sudo apt-get update -y
sudo apt-get install -y \
    xfce4 \
    xfce4-goodies \
    xrdp \
    tailscale \
    dbus-x11 \
    tightvncserver

# 4. Prevent duplicate user clashes - Create unique sandbox user
if id "$MY_USER" &>/dev/null; then
    echo "User $MY_USER exists. Reconfiguring..."
else
    sudo useradd -m -s /bin/bash "$MY_USER"
    echo "$MY_USER:$MY_PASS" | sudo chpasswd
    sudo usermod -aG sudo "$MY_USER"
fi

# 5. Configure XRDP to use XFCE for this specific user
echo "xfce4-session" > /home/$MY_USER/.xsession
chown -R $MY_USER:$MY_USER /home/$MY_USER/.xsession

# 6. Optimize XRDP performance & change default port to bypass generic scans
# Standard RDP is 3389; changing it to 3390 makes it unique and less "copied"
sudo sed -i 's/port=3389/port=3390/g' /etc/xrdp/xrdp.ini
sudo adduser xrdp ssl-cert

# 7. Start Services
sudo service xrdp restart

echo "========================================="
echo " Setup Complete! Port shifted to 3390.   "
echo "========================================="
