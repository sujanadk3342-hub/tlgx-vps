FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install XFCE, VNC, noVNC, and clean up
RUN apt-get update && apt-get install -y \
    xfce4 \
    xfce4-goodies \
    tigervnc-standalone-server \
    novnc \
    websockify \
    fluxbox \
    & \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set up a default VNC password (change 'vscode' if you want)
RUN mkdir -p ~/.vnc && echo "vscode" | vncpass -stdin

# Expose noVNC default port
EXPOSE 6080

# Start noVNC and VNC server on container launch
CMD ["sh", "-c", "vncserver :1 -geometry 1280x720 -depth 24 && websockify --web /usr/share/novnc 6080 localhost:5901"]
