echo -e "${RED}Checking and installing Tailscale first...${NC}"

# Install Tailscale if missing
if ! command -v tailscale >/dev/null 2>&1; then
    curl -fsSL https://tailscale.com/install.sh | sh
else
    echo -e "${GREEN}Tailscale is already installed.${NC}"
fi

echo -e "${YELLOW}Starting Tailscale background service...${NC}"

# Stop old instances
pkill tailscaled 2>/dev/null || true

# Try normal service start
service tailscaled start 2>/dev/null || true

sleep 3

# Fallback for containers without systemd
if ! pgrep tailscaled >/dev/null; then
    echo -e "${YELLOW}Starting tailscaled in userspace mode...${NC}"

    nohup tailscaled \
        --tun=userspace-networking \
        --state=/tmp/tailscaled.state \
        > /tmp/tailscaled.log 2>&1 &

    sleep 5
fi

# Verify daemon started
if ! pgrep tailscaled >/dev/null; then
    echo -e "${RED}Failed to start tailscaled.${NC}"

    if [ -f /tmp/tailscaled.log ]; then
        cat /tmp/tailscaled.log
    fi

    exit 1
fi

echo -e "${GREEN}tailscaled started successfully.${NC}"

# Authenticate
if [ -n "$TS_KEY" ]; then
    echo -e "${GREEN}Auth key detected. Authenticating...${NC}"

    tailscale up \
        --authkey="$TS_KEY" \
        --accept-routes \
        --accept-dns=false

else
    echo -e "${YELLOW}No TS_KEY variable found. Authenticate using the URL below:${NC}"
    tailscale up
fi

sleep 5

# Obtain Tailscale IPv4
TS_IP=$(tailscale ip -4 2>/dev/null | head -n1)

if [ -z "$TS_IP" ]; then
    echo -e "${RED}Failed to get Tailscale IP.${NC}"

    echo -e "${YELLOW}Tailscale status:${NC}"
    tailscale status || true

    exit 1
fi

echo -e "${GREEN}Tailscale IP detected: $TS_IP${NC}"
