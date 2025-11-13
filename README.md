# shmux ⚡

> **SSH + tmux multiplexer** - One command to connect to any server and session

Stop wasting time SSHing into servers and hunting for tmux sessions. **shmux** automates your entire remote development workflow into a single interactive command.

```bash
$ shmux
╔════════════════════════════════════════════════════════════════╗
║                VPN + SSH + tmux Speedrun                       ║
╚════════════════════════════════════════════════════════════════╝

Profile: Home Network
Server: Desktop

✓ OpenVPN already running
✓ SOCKS proxy already running on port 1080
[3/3] Connecting to Desktop...

Available tmux sessions:

  1. default
  2. gpu-01
  3. gpu-02

Enter number to attach (or press ESC/Enter to skip):
```

## Why shmux?

**Traditional workflow:**
```bash
# Remember which server...
ssh user@192.168.1.100

# List tmux sessions...
tmux list-sessions

# Finally attach
tmux attach -t my-session

# Repeat for each server you manage...
```

**With shmux:**
```bash
shmux                              # Interactive: pick profile, server, session
shmux home Desktop my-session      # Direct: one command, done
```

That's it. No remembering IPs, no manual tmux commands.

## Features

### 🖥️ Multi-Server Management
- Organize servers into profiles (home, work, lab)
- Interactive numbered menus for quick selection
- Per-server credentials (passwords or SSH keys)

### ⚡ Smart Workflow
- One command to SSH + attach to tmux
- Auto-selects when only one option exists (no menu spam)
- Terminal type compatibility built-in
- Connection reuse where applicable

### 🎯 Flexible Usage
- Fully interactive: pick profile → server → session
- Direct mode: `shmux profile server session`
- Mix and match: specify what you know, pick the rest

### 🔐 Optional VPN Integration
- Can manage OpenVPN connections per profile
- SOCKS proxy tunneling for selective routing
- Useful for homelab, corporate networks, or cloud private networks

## Quick Start

### Installation

1. **Clone the repo:**
   ```bash
   git clone https://github.com/yourusername/shmux.git
   cd shmux
   ```

2. **Create your first profile:**
   ```bash
   cp profiles/home-network.example.sh profiles/home.sh
   nano profiles/home.sh
   ```

3. **Edit the profile:**
   ```bash
   PROFILE_NAME="Home Network"
   VPN_CONFIG_FILE="$HOME/Documents/my-vpn.ovpn"
   SOCKS_PORT=1080

   SERVERS=(
       "Desktop|user@192.168.1.100"
       "NAS|admin@192.168.1.50"
   )

   SSH_PASSWORD="yourpass"  # Optional
   ```

4. **Make executable and add alias:**
   ```bash
   chmod +x shmux.sh

   # Add to ~/.zshrc or ~/.bashrc:
   alias shmux='~/shmux/shmux.sh'

   source ~/.zshrc  # Reload shell
   ```

5. **Run it:**
   ```bash
   vpn
   ```

### Prerequisites

- **macOS** (Linux should work with minor tweaks)
- **OpenVPN**: `brew install openvpn`
- **sshpass** (optional): `brew install hudochenkov/sshpass/sshpass`
- OpenVPN config file (`.ovpn`)
- SSH access to at least one server
- tmux running on remote server(s)

## Usage Guide

### Interactive Mode (Recommended for First-Time)

Just type:
```bash
shmux
```

You'll be guided through:
1. **Profile selection** (if multiple profiles exist)
2. **Server selection** (if multiple servers in profile)
3. **Tmux session selection** (with option to skip)

### Command-Line Arguments

Skip menus by providing arguments:

```bash
shmux [profile] [server] [tmux-session]
```

**Examples:**

```bash
# Interactive: pick everything
shmux

# Pick server and session
shmux home-network

# Pick session only
shmux home-network Desktop

# Direct connect (no menus)
shmux home-network Desktop gpu-session
```

### Real-World Examples

**Daily work session:**
```bash
shmux work "Dev Server" my-project
```

**Quick check on NAS:**
```bash
shmux home NAS
```

**Exploring available options:**
```bash
shmux  # See all profiles, servers, and sessions
```

**Switching between servers:**
```bash
shmux home Desktop     # Work on desktop
# ... do stuff ...
# Open new terminal:
shmux home NAS         # Switch to NAS
```

## Profile Configuration

Profiles live in `profiles/` and define a VPN network + its servers.

### Profile Structure

```bash
#!/bin/bash
# Profile: [Your Network Name]

# Display name shown in menus
PROFILE_NAME="Home Network"

# Path to your OpenVPN config file
VPN_CONFIG_FILE="$HOME/Documents/home-vpn.ovpn"

# SOCKS proxy port (must be unique per profile!)
SOCKS_PORT=1080

# List of servers: "Display Name|user@host|password"
# Password is optional - leave empty to use SSH keys or be prompted
SERVERS=(
    "Desktop|user@192.168.1.100|mypassword"
    "NAS|admin@192.168.1.50|"
    "Media Server|pi@192.168.1.150|different-pw"
)
```

### Creating Multiple Profiles

Each profile = one VPN network:

```bash
# Home network
cp profiles/home-network.example.sh profiles/home.sh
nano profiles/home.sh  # Edit with your home VPN details

# Work network
cp profiles/work-network.example.sh profiles/work.sh
nano profiles/work.sh  # Edit with your work VPN details

# Lab network
cp profiles/home-network.example.sh profiles/lab.sh
nano profiles/lab.sh   # Edit with your lab VPN details
```

**Important:** Use different `SOCKS_PORT` for each profile:
- Home: 1080
- Work: 1081
- Lab: 1082

### Server Format

```bash
SERVERS=(
    "Display Name|ssh_user@hostname_or_ip|password"
)
```

The password field is optional - leave it empty to use SSH keys or be prompted:

**Examples:**
```bash
SERVERS=(
    "Main Server|root@192.168.1.100|secretpass"        # With password
    "Dev Box|developer@dev.mycompany.com|"             # Uses SSH key
    "Build Server|jenkins@10.0.0.50|build123"          # With password
    "My Desktop|myuser@home.ddns.net|"                 # Prompts for password
)
```

**Best practice:** Leave passwords empty and use SSH keys for better security.

## Advanced Usage

### Multiple Networks Example

A complete setup for home + work:

```
~/shmux/
├── profiles/
│   ├── home.sh              # SOCKS_PORT=1080
│   │   Servers:
│   │   - Desktop (192.168.1.100)
│   │   - NAS (192.168.1.50)
│   │   - Pi (192.168.1.150)
│   │
│   └── work.sh              # SOCKS_PORT=1081
│       Servers:
│       - Dev Server (10.0.1.50)
│       - Staging (10.0.1.51)
│       - Database (10.0.1.100)
```

**Workflow:**
```bash
# Morning: connect to work
shmux work "Dev Server" dev-session

# Evening: check home server
shmux home Desktop

# Both VPNs can run simultaneously (different ports)!
```

### Running Multiple VPNs Simultaneously

Because each profile uses a unique SOCKS port, you can have multiple VPNs active:

```bash
# Terminal 1: Connect via home network
shmux home Desktop

# Terminal 2: Connect via work network (in parallel!)
shmux work "Dev Server"
```

### SSH Key Authentication (Recommended)

For better security, use SSH keys instead of passwords:

1. **Generate key:**
   ```bash
   ssh-keygen -t ed25519
   ```

2. **Copy to server:**
   ```bash
   ssh-copy-id user@your-server
   ```

3. **Remove password from profile:**
   ```bash
   SSH_PASSWORD=""  # Leave empty
   ```

Now connections will use your key automatically!

### Auto-Selection Behavior

VPN Speedrun is smart about when to show menus:

- **1 profile** → auto-selected (no menu)
- **1 server in profile** → auto-selected (no menu)
- **Multiple options** → shows numbered menu
- **Tmux sessions** → always shows menu (can press Enter to skip)

This means if you have one profile with one server, you'll go straight to session selection!

## Stopping VPN & Proxy

The VPN and SOCKS proxy continue running after you disconnect. This is intentional (faster reconnects).

**To stop everything:**

```bash
# Stop OpenVPN
sudo killall openvpn

# Stop SOCKS proxy (adjust port as needed)
kill $(lsof -ti:1080)  # Home network
kill $(lsof -ti:1081)  # Work network
```

**To stop a specific profile's VPN:**
```bash
# Find the process
ps aux | grep openvpn

# Kill by config file
pkill -f "openvpn.*home-vpn.ovpn"
```

## Troubleshooting

### "No profiles found!"

**Problem:** No `.sh` files in `profiles/` (except `.example.sh`)

**Solution:**
```bash
cp profiles/home-network.example.sh profiles/my-network.sh
nano profiles/my-network.sh
```

### "missing or unsuitable terminal: xterm-ghostty"

**Problem:** Your terminal type isn't recognized by tmux

**Solution:** Already handled! The script sets `TERM=xterm-256color` automatically. If you still see this, check your remote server has xterm terminfo:
```bash
# On remote server:
toe | grep xterm-256color
```

### sshpass not working or not found

**Problem:** sshpass not installed or password auth failing

**Solution 1:** Install sshpass
```bash
brew install hudochenkov/sshpass/sshpass
```

**Solution 2:** Use SSH keys (better!)
```bash
ssh-copy-id user@your-server
# Then remove SSH_PASSWORD from profile
```

**Solution 3:** Leave `SSH_PASSWORD=""` and enter manually each time

### SOCKS proxy port already in use

**Problem:** Port conflict between profiles

**Solution:** Each profile needs a unique `SOCKS_PORT`:
```bash
# profiles/home.sh
SOCKS_PORT=1080

# profiles/work.sh
SOCKS_PORT=1081

# profiles/lab.sh
SOCKS_PORT=1082
```

### OpenVPN fails to start

**Problem:** Sudo password issues or bad config file

**Common fixes:**
```bash
# Test your config manually
sudo /opt/homebrew/opt/openvpn/sbin/openvpn --config ~/your-vpn.ovpn

# Check config file path in profile
# Make sure VPN_CONFIG_FILE points to correct .ovpn file

# Check OpenVPN logs
tail -f /tmp/openvpn-*.log
```

### "Server 'XXX' not found in profile!"

**Problem:** Server name doesn't match any in `SERVERS` array

**Solution:** Server names are **case-sensitive**. Check your profile:
```bash
# In profile:
SERVERS=("Desktop|user@host")

# This works:
shmux home Desktop

# This fails:
shmux home desktop  # lowercase doesn't match
```

### Connection drops or times out

**Problem:** VPN route needs time to establish

**Solution:** The script waits 3 seconds after VPN start. If issues persist:
```bash
# Increase sleep time in shmux.sh line ~170:
sleep 5  # instead of sleep 3
```

## Security Best Practices

### ⚠️ Profile Files Are Executable Code

**Important:** Profile files (`.sh`) are executed as bash scripts. Only use profiles you trust and never run profiles from unknown sources.

### 1. Protect Your Profiles
```bash
# Profiles may contain passwords - restrict access
chmod 600 profiles/*.sh

# They're gitignored by default, but double-check:
git status  # Should NOT show profiles/*.sh (except .example.sh)
```

### 2. Use SSH Keys (Recommended)
SSH keys are more secure than passwords and prevent password exposure:

```bash
# Generate key
ssh-keygen -t ed25519 -C "your-email@example.com"

# Add to server
ssh-copy-id user@server

# Remove password from profile
SSH_PASSWORD=""  # Leave empty to use SSH key
```

### 3. Avoid Committing Sensitive Files
The `.gitignore` automatically excludes:
- `profiles/*.sh` (your actual configs)
- But **includes** `profiles/*.example.sh` (templates)

**Never commit files containing:**
- SSH passwords
- VPN credentials
- API keys or tokens

### 4. Different Credentials Per Network
Each profile can have different SSH credentials:
```bash
# profiles/home.sh
SSH_PASSWORD="home-password"

# profiles/work.sh
SSH_PASSWORD=""  # Uses SSH key
```

### 5. Review OpenVPN Configs
Ensure your `.ovpn` files don't route ALL traffic if you want selective routing:
```bash
# In your .ovpn, look for:
route-nopull  # Good: selective routing
# redirect-gateway  # Bad: routes all traffic
```

### 6. Host Key Verification Disabled
This tool uses `StrictHostKeyChecking=no` for convenience, which disables SSH host key verification. This means:
- ✅ Works with dynamic IPs and new servers
- ⚠️ You're vulnerable to man-in-the-middle attacks

If connecting to production servers, consider enabling strict host checking.

## FAQ

**Q: Can I use this without a VPN?**
A: Yes! The VPN part is optional. You can create a profile with just servers and leave the VPN config empty (though you'll need to modify the script to skip VPN setup).

**Q: Does this work on Linux?**
A: Yes, with minor tweaks. Main change: OpenVPN path. Change `/opt/homebrew/opt/openvpn/sbin/openvpn` to `/usr/sbin/openvpn` or wherever your OpenVPN binary lives.

**Q: Can I connect to servers without tmux?**
A: Yes! Just press Enter/ESC when the tmux session menu appears, and you'll drop into a regular SSH shell.

**Q: What if my server doesn't have tmux?**
A: The script will detect no sessions and connect you to a regular SSH shell automatically.

**Q: Can I use this with WireGuard instead of OpenVPN?**
A: Not currently, but it would be a great contribution! The script is structured to make this fairly easy to add.

**Q: Why use SOCKS proxy?**
A: The SOCKS proxy (SSH tunnel) allows applications to route traffic through the VPN selectively. This is useful if you don't want all your traffic going through the VPN.

**Q: How do I update the script?**
A:
```bash
cd ~/shmux
git pull
# Your profiles/*.sh are gitignored and won't be affected
```

## Contributing

Contributions welcome! Here are some ideas:

- [ ] WireGuard support
- [ ] Linux compatibility improvements
- [ ] Windows WSL support
- [ ] Config validation command
- [ ] Profile import/export
- [ ] Tab completion for zsh/bash
- [ ] systemd service file for auto-start
- [ ] Reconnect on disconnect

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Credits

Built with ☕ to solve the "why do I have to do this every single day" problem.

If this saves you time, give it a ⭐!

## Support

- **Issues:** [GitHub Issues](https://github.com/yourusername/shmux/issues)
- **Discussions:** [GitHub Discussions](https://github.com/yourusername/shmux/discussions)

---

**Happy speedrunning! ⚡**
