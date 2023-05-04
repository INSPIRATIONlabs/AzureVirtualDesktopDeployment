#!/bin/bash

# Check if script is running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Check for required parameters
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <auth_key> <comma_separated_networks>"
    exit 1
fi

AUTH_KEY="$1"
NETWORKS="$2"

# Detect Ubuntu version
UBUNTU_VERSION=$(lsb_release -sc)

# Add Tailscale repository
curl -fsSL "https://pkgs.tailscale.com/stable/ubuntu/${UBUNTU_VERSION}.noarmor.gpg" | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl -fsSL "https://pkgs.tailscale.com/stable/ubuntu/${UBUNTU_VERSION}.tailscale-keyring.list" | sudo tee /etc/apt/sources.list.d/tailscale.list

# Update package list and install Tailscale
sudo apt-get update
sudo apt-get install -y tailscale

# Authenticate Tailscale and set up networks
sudo tailscale up --authkey="${AUTH_KEY}" --advertise-routes="${NETWORKS}"

# Enable and start the Tailscale service
sudo systemctl enable tailscale
sudo systemctl start tailscale

echo "Tailscale installation and configuration complete."
