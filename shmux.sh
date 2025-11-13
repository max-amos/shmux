#!/bin/bash
# Multi-profile VPN + SSH + tmux launcher
# Usage: ./vpn_start.sh [profile_name] [server_name] [tmux_session_name]

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILES_DIR="$SCRIPT_DIR/profiles"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to list available profiles
list_profiles() {
    echo "Available profiles:"
    echo ""
    local count=0
    local profile_files=()

    for profile in "$PROFILES_DIR"/*.sh; do
        if [ -f "$profile" ] && [[ ! "$profile" =~ \.example\.sh$ ]]; then
            profile_files+=("$profile")
            count=$((count + 1))
            local basename=$(basename "$profile" .sh)
            echo "  $count. $basename"
        fi
    done

    echo ""

    if [ $count -eq 0 ]; then
        echo -e "${RED}No profiles found!${NC}"
        echo "Create a profile by copying an example:"
        echo "  cp $PROFILES_DIR/home-network.example.sh $PROFILES_DIR/my-network.sh"
        exit 1
    fi

    echo "${profile_files[@]}"
}

# Function to select a profile
select_profile() {
    local profile_files=($(list_profiles))
    local count=${#profile_files[@]}

    if [ $count -eq 1 ]; then
        # Only one profile, use it automatically
        SELECTED_PROFILE="${profile_files[0]}"
        return
    fi

    echo -e "${YELLOW}Select profile (1-$count):${NC}"
    read -t 30 -n 1 choice
    echo ""

    if [[ "$choice" =~ ^[0-9]$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$count" ]; then
        SELECTED_PROFILE="${profile_files[$((choice-1))]}"
    else
        echo "Invalid selection"
        exit 1
    fi
}

# Function to select a server from the profile
select_server() {
    if [ ${#SERVERS[@]} -eq 0 ]; then
        echo -e "${RED}No servers defined in profile!${NC}"
        exit 1
    fi

    if [ ${#SERVERS[@]} -eq 1 ]; then
        # Only one server, use it automatically
        local server_info="${SERVERS[0]}"
        SERVER_NAME=$(echo "$server_info" | cut -d'|' -f1)
        SSH_SERVER=$(echo "$server_info" | cut -d'|' -f2)
        SSH_PASSWORD=$(echo "$server_info" | cut -d'|' -f3)
        return
    fi

    echo "Available servers:"
    echo ""

    for i in "${!SERVERS[@]}"; do
        local server_info="${SERVERS[$i]}"
        local display_name=$(echo "$server_info" | cut -d'|' -f1)
        echo "  $((i+1)). $display_name"
    done
    echo ""

    echo -e "${YELLOW}Select server (1-${#SERVERS[@]}):${NC}"
    read -t 30 -n 1 choice
    echo ""

    if [[ "$choice" =~ ^[0-9]$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#SERVERS[@]}" ]; then
        local server_info="${SERVERS[$((choice-1))]}"
        SERVER_NAME=$(echo "$server_info" | cut -d'|' -f1)
        SSH_SERVER=$(echo "$server_info" | cut -d'|' -f2)
        SSH_PASSWORD=$(echo "$server_info" | cut -d'|' -f3)
    else
        echo "Invalid selection"
        exit 1
    fi
}

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                VPN + SSH + tmux Speedrun                       ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Parse arguments or select interactively
PROFILE_ARG="$1"
SERVER_ARG="$2"
TMUX_SESSION="$3"

if [ -n "$PROFILE_ARG" ]; then
    # Profile specified as argument
    # Prevent path traversal attacks
    if [[ "$PROFILE_ARG" =~ [./] ]]; then
        echo -e "${RED}Invalid profile name. Use filename only (no paths).${NC}"
        exit 1
    fi
    SELECTED_PROFILE="$PROFILES_DIR/${PROFILE_ARG}.sh"
    if [ ! -f "$SELECTED_PROFILE" ]; then
        echo -e "${RED}Profile '$PROFILE_ARG' not found!${NC}"
        exit 1
    fi
else
    # Interactive profile selection
    select_profile
fi

# Load the selected profile
source "$SELECTED_PROFILE"

PROFILE_BASENAME=$(basename "$SELECTED_PROFILE" .sh)
echo -e "${BLUE}Profile: $PROFILE_NAME${NC}"

# Security hint if using password authentication
if [ -n "$SSH_PASSWORD" ]; then
    echo -e "${YELLOW}Tip: Consider using SSH keys instead of passwords (see README)${NC}"
fi
echo ""

# Select server (from argument or interactively)
if [ -n "$SERVER_ARG" ]; then
    # Find server by name
    for server_info in "${SERVERS[@]}"; do
        display_name=$(echo "$server_info" | cut -d'|' -f1)
        if [ "$display_name" = "$SERVER_ARG" ]; then
            SERVER_NAME="$display_name"
            SSH_SERVER=$(echo "$server_info" | cut -d'|' -f2)
            SSH_PASSWORD=$(echo "$server_info" | cut -d'|' -f3)
            break
        fi
    done

    if [ -z "$SSH_SERVER" ]; then
        echo -e "${RED}Server '$SERVER_ARG' not found in profile!${NC}"
        exit 1
    fi
else
    select_server
fi

echo -e "${BLUE}Server: $SERVER_NAME${NC}"
echo ""

# Step 1: Start OpenVPN
if pgrep -f "openvpn.*$VPN_CONFIG_FILE" > /dev/null; then
    echo -e "${GREEN}✓ OpenVPN already running${NC}"
else
    echo -e "${BLUE}[1/3] Starting OpenVPN...${NC}"
    sudo /opt/homebrew/opt/openvpn/sbin/openvpn \
        --config "$VPN_CONFIG_FILE" \
        --daemon \
        --log /tmp/openvpn-${PROFILE_BASENAME}.log

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ OpenVPN started${NC}"
        sleep 3
    else
        echo "✗ Failed to start OpenVPN"
        exit 1
    fi
fi

# Step 2: Start SOCKS proxy
if lsof -ti:$SOCKS_PORT > /dev/null 2>&1; then
    echo -e "${GREEN}✓ SOCKS proxy already running on port $SOCKS_PORT${NC}"
else
    echo -e "${BLUE}[2/3] Starting SOCKS proxy on port $SOCKS_PORT...${NC}"

    # Try with sshpass first if password is provided
    if [ -n "$SSH_PASSWORD" ] && command -v sshpass &> /dev/null; then
        export SSHPASS="$SSH_PASSWORD"
        sshpass -e ssh -D $SOCKS_PORT -N -f \
            -o StrictHostKeyChecking=no \
            -o UserKnownHostsFile=/dev/null \
            -o ConnectTimeout=10 \
            -o LogLevel=ERROR \
            "$SSH_SERVER" 2>/dev/null
        unset SSHPASS
    else
        # Fall back to manual password entry
        ssh -D $SOCKS_PORT -N -f \
            -o StrictHostKeyChecking=no \
            -o UserKnownHostsFile=/dev/null \
            -o ConnectTimeout=10 \
            "$SSH_SERVER"
    fi

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ SOCKS proxy started${NC}"
        sleep 1
    else
        echo -e "${YELLOW}⚠ SOCKS proxy failed (continuing anyway)${NC}"
    fi
fi

# Step 3: SSH into desktop and attach to tmux
echo -e "${BLUE}[3/3] Connecting to $SERVER_NAME...${NC}"
echo ""

if [ -z "$TMUX_SESSION" ]; then
    # No session specified - fetch list and let user choose
    if [ -n "$SSH_PASSWORD" ] && command -v sshpass &> /dev/null; then
        # Get list of tmux sessions
        export SSHPASS="$SSH_PASSWORD"
        SESSIONS=$(sshpass -e ssh \
            -o StrictHostKeyChecking=no \
            -o UserKnownHostsFile=/dev/null \
            -o LogLevel=ERROR \
            "$SSH_SERVER" "tmux list-sessions -F '#{session_name}' 2>/dev/null")

        if [ -n "$SESSIONS" ]; then
            echo "Available tmux sessions:"
            echo ""

            # Convert to array
            SESSION_ARRAY=()
            while IFS= read -r line; do
                SESSION_ARRAY+=("$line")
            done <<< "$SESSIONS"

            # Display numbered list
            for i in "${!SESSION_ARRAY[@]}"; do
                echo "  $((i+1)). ${SESSION_ARRAY[$i]}"
            done
            echo ""
            echo -e "${YELLOW}Enter number to attach (or press ESC/Enter to skip):${NC}"

            # Read user input with timeout for ESC detection
            read -t 30 -n 1 choice
            echo ""

            # Check if user selected a number
            if [[ "$choice" =~ ^[0-9]$ ]]; then
                idx=$((choice-1))
                if [ $idx -ge 0 ] && [ $idx -lt ${#SESSION_ARRAY[@]} ]; then
                    TMUX_SESSION="${SESSION_ARRAY[$idx]}"
                    echo "Attaching to: $TMUX_SESSION"
                    echo ""
                    TERM=xterm-256color sshpass -e ssh -t \
                        -o StrictHostKeyChecking=no \
                        -o UserKnownHostsFile=/dev/null \
                        "$SSH_SERVER" "TERM=xterm-256color tmux attach-session -t \"$TMUX_SESSION\""
                else
                    echo "Invalid selection. Connecting to shell..."
                    echo ""
                    sshpass -e ssh \
                        -o StrictHostKeyChecking=no \
                        -o UserKnownHostsFile=/dev/null \
                        "$SSH_SERVER"
                fi
            else
                echo "Skipping tmux. Connecting to shell..."
                echo ""
                sshpass -e ssh \
                    -o StrictHostKeyChecking=no \
                    -o UserKnownHostsFile=/dev/null \
                    "$SSH_SERVER"
            fi
        else
            echo "No tmux sessions found. Connecting to shell..."
            echo ""
            sshpass -e ssh \
                -o StrictHostKeyChecking=no \
                -o UserKnownHostsFile=/dev/null \
                "$SSH_SERVER"
        fi
        unset SSHPASS
    else
        ssh -t "$SSH_SERVER" "tmux list-sessions 2>/dev/null || echo '(no sessions found)'; echo ''; echo 'Run: tmux attach -t <session_name>'; bash -l"
    fi
else
    # Session specified - attach directly
    echo "Attaching to tmux session: $TMUX_SESSION"
    echo ""

    if [ -n "$SSH_PASSWORD" ] && command -v sshpass &> /dev/null; then
        export SSHPASS="$SSH_PASSWORD"
        TERM=xterm-256color sshpass -e ssh -t \
            -o StrictHostKeyChecking=no \
            -o UserKnownHostsFile=/dev/null \
            "$SSH_SERVER" "TERM=xterm-256color tmux attach-session -t \"$TMUX_SESSION\" || tmux new-session -s \"$TMUX_SESSION\""
        unset SSHPASS
    else
        TERM=xterm-256color ssh -t "$SSH_SERVER" "TERM=xterm-256color tmux attach-session -t \"$TMUX_SESSION\" || tmux new-session -s \"$TMUX_SESSION\""
    fi
fi

echo ""
echo -e "${GREEN}Session ended.${NC}"
