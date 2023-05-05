#!/bin/bash

# Check if script is running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

usage() {
    echo "Usage: $0 --auth-key <auth_key> --networks <comma_separated_networks> [--enable-routing]"
    exit 1
}

# Set default values for parameters
AUTH_KEY=""
NETWORKS=""
ENABLE_ROUTING=0

# Parse named parameters
while [ "$#" -gt 0 ]; do
    case "$1" in
        --auth-key)
            AUTH_KEY="$2"
            shift 2
            ;;
        --networks)
            NETWORKS="$2"
            shift 2
            ;;
        --enable-routing)
            ENABLE_ROUTING=1
            shift
            ;;
        *)
            usage
            ;;
    esac
done

# Check if required parameters are set
if [ -z "$AUTH_KEY" ] || [ -z "$NETWORKS" ]; then
    usage
fi

# Detect Ubuntu version
UBUNTU_VERSION=$(lsb_release -sc)

# Add Tailscale repository
curl -fsSL "https://pkgs.tailscale.com/stable/ubuntu/${UBUNTU_VERSION}.noarmor.gpg" | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl -fsSL "https://pkgs.tailscale.com/stable/ubuntu/${UBUNTU_VERSION}.tailscale-keyring.list" | sudo tee /etc/apt/sources.list.d/tailscale.list

# Update package list and install Tailscale
sudo apt-get update
sudo apt-get install -y tailscale

# Authenticate Tailscale and set up networks
if [ "$ENABLE_ROUTING" -eq 1 ]; then
    sudo tailscale up --authkey="${AUTH_KEY}" --advertise-routes="${NETWORKS}" --accept-routes
else
    sudo tailscale up --authkey="${AUTH_KEY}" --advertise-routes="${NETWORKS}"
fi

# Enable routing if requested
if [ "$ENABLE_ROUTING" -eq 1 ]; then
    echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
    echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
    sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
fi

# Enable and start the Tailscale service
sudo systemctl enable tailscale
sudo systemctl start tailscale

echo "Tailscale installation and configuration complete."
