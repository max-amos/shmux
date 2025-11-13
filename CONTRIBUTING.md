# Contributing to VPN Speedrun

Thanks for your interest in contributing! This project aims to make remote development workflows faster and more enjoyable.

## How to Contribute

### Reporting Bugs

Found a bug? Please open an issue with:

1. **Clear title** - Describe the problem concisely
2. **Steps to reproduce** - Exact commands and what happened
3. **Expected behavior** - What should have happened
4. **Environment details**:
   - OS (macOS version, Linux distro, etc.)
   - Shell (zsh, bash, etc.)
   - OpenVPN version
   - sshpass version (if applicable)
5. **Relevant logs** - Output from `/tmp/openvpn-*.log` if VPN-related

### Suggesting Features

Have an idea? Open an issue with:

1. **Use case** - What problem does this solve?
2. **Proposed solution** - How would it work?
3. **Alternatives** - Other ways you considered

### Pull Requests

We love PRs! Here's the process:

1. **Fork the repo**
2. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes**
4. **Test thoroughly** - Try multiple scenarios
5. **Commit with clear messages**:
   ```bash
   git commit -m "Add support for WireGuard VPNs"
   ```
6. **Push and create PR**:
   ```bash
   git push origin feature/your-feature-name
   ```

### Code Style

- **Shell script best practices**:
  - Use `#!/bin/bash` shebang
  - Quote variables: `"$VAR"` not `$VAR`
  - Check command success: `if [ $? -eq 0 ]; then`
  - Use meaningful variable names
  - Add comments for complex logic

- **Consistency**:
  - Follow existing code style
  - Use 4 spaces for indentation (no tabs)
  - Keep functions focused and single-purpose

### Testing

Before submitting, please test:

1. **Fresh installation** - Does setup work from scratch?
2. **Multiple profiles** - Profile selection works?
3. **Multiple servers** - Server selection works?
4. **Edge cases**:
   - No profiles (error handling)
   - Single profile (auto-select)
   - No tmux sessions (graceful fallback)
   - Invalid arguments (clear error messages)
5. **Cleanup** - Script doesn't leave orphaned processes

### Documentation

If your change affects usage:

- Update `README.md` with new features/options
- Add examples showing how to use it
- Update profile examples if config format changes
- Add FAQ entry for common issues

## Development Ideas

Here are some features we'd love to see:

### High Priority

- **WireGuard support** - Alternative to OpenVPN
- **Linux compatibility** - Fix hardcoded macOS paths
- **Windows WSL support** - Test and document WSL usage
- **Config validator** - Check profile syntax before running
- **Better error messages** - More helpful troubleshooting

### Medium Priority

- **Profile manager** - CLI tool for managing profiles
- **Tab completion** - zsh/bash autocomplete for profiles/servers
- **Connection health check** - Verify VPN/proxy before SSH
- **Reconnect on disconnect** - Auto-retry failed connections
- **Multiple SSH keys** - Per-server SSH key support

### Nice to Have

- **systemd integration** - Auto-start VPNs on boot
- **Notification support** - macOS notifications for events
- **Connection status** - See all active VPN/proxy connections
- **Profile import/export** - Share profiles safely (without passwords)
- **Parallel tmux** - Open multiple sessions in split panes
- **Custom commands** - Run commands on connect

## Project Structure

```
vpn-speedrun/
├── vpn_start.sh           # Main script
├── profiles/              # Profile configs
│   ├── *.example.sh      # Example templates (committed)
│   └── *.sh              # User configs (gitignored)
├── README.md             # User documentation
├── CONTRIBUTING.md       # This file
├── LICENSE               # MIT license
└── .gitignore           # Ignore sensitive configs
```

## Key Functions in vpn_start.sh

- `list_profiles()` - Show available profiles
- `select_profile()` - Interactive profile picker
- `select_server()` - Interactive server picker
- OpenVPN management - Start/check VPN
- SOCKS proxy management - Start/check SSH tunnel
- tmux session handling - List and attach

## Security Considerations

When contributing, keep security in mind:

1. **Never log passwords** - Don't add debug output for SSH_PASSWORD
2. **Validate inputs** - Check user input for injection attacks
3. **Secure defaults** - Default to safer options
4. **Document security implications** - If feature affects security, explain it

## Questions?

- Open a Discussion for general questions
- Open an Issue for specific problems
- Tag @maintainers for urgent security issues

## Code of Conduct

Be respectful and constructive. We're all here to make development easier.

## License

By contributing, you agree your contributions will be licensed under the MIT License.

---

**Thank you for contributing! 🎉**
