#!/bin/bash
# Profile: Home Network
# Copy this to profiles/home-network.sh and customize

# Profile display name
PROFILE_NAME="Home Network"

# OpenVPN configuration file path
VPN_CONFIG_FILE="$HOME/Documents/home-vpn.ovpn"

# SOCKS proxy port (each profile should use a different port)
SOCKS_PORT=1080

# List of servers in this network
# Format: "display_name|user@host|password"
# Password is optional - leave empty to use SSH keys or be prompted
SERVERS=(
    "Desktop|user@192.168.1.100|mypassword"
    "NAS|admin@192.168.1.50|"
    "Media Server|pi@192.168.1.150|different-pw"
)
