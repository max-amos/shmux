#!/bin/bash
# Profile: Work Network
# Copy this to profiles/work-network.sh and customize

# Profile display name
PROFILE_NAME="Work Network"

# OpenVPN configuration file path
VPN_CONFIG_FILE="$HOME/Documents/work-vpn.ovpn"

# SOCKS proxy port (each profile should use a different port)
SOCKS_PORT=1081

# List of servers in this network
# Format: "display_name|user@host|password"
# Password is optional - leave empty to use SSH keys or be prompted
SERVERS=(
    "Dev Server|dev@10.0.1.50|"
    "Build Server|jenkins@10.0.1.51|"
    "Database Server|admin@10.0.1.100|"
)
