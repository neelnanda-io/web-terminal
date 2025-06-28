# Web Terminal Access System

A secure web-based terminal interface that allows remote access to your Mac's terminal through a VPS proxy. Access your development environment from any device with a web browser.

## Features

- 🌐 **Web-based terminal access** - Access your Mac terminal from any browser
- 📱 **Mobile-friendly interface** - Optimized controls for touch devices  
- 🔒 **Secure authentication** - HTTP Basic Auth with configurable credentials
- 🖥️ **Persistent sessions** - tmux integration for session management
- 🚇 **Reverse SSH tunnel** - Secure connection through VPS proxy
- 🔧 **SSH fallback** - Alternative SSH access when web terminal has issues

## Quick Start

### Prerequisites

- macOS laptop (local machine)
- Linux VPS with public IP (Ubuntu/Debian)
- SSH key-based access to VPS
- Homebrew installed on Mac

### Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd web-terminal
   ```

2. **Configure credentials:**
   ```bash
   cp credentials.example.sh credentials.sh
   # Edit credentials.sh with your VPS details
   ```

3. **Run the setup:**
   ```bash
   ./fix-web-terminal.sh
   ```

4. **Access your terminal:**
   - URL: `http://YOUR_VPS_IP/`
   - Username: `admin`
   - Password: `webterm123` (configurable)

## Architecture

```
┌─────────────┐       ┌─────────────┐       ┌─────────────┐
│   Browser   │──────▶│     VPS     │──────▶│   Mac       │
│             │ HTTPS │   (nginx)   │ SSH   │   (ttyd)    │
└─────────────┘       └─────────────┘ Tunnel└─────────────┘
```

1. **ttyd** runs on your Mac, serving tmux sessions over HTTP
2. **autossh** creates a persistent reverse tunnel to the VPS
3. **nginx** on the VPS proxies requests to the tunneled port
4. **Basic Auth** protects access with username/password

## Mobile Access

### Web Interface
The web terminal includes a mobile-optimized control panel:
- Tap **☰** to open the control panel
- Use on-screen buttons for arrow keys, Ctrl commands, etc.
- Access specific tmux windows via URL (e.g., `/Code`)

### SSH Access (Recommended for Mobile)
For better mobile experience, use SSH clients:

#### Termius (Android/iOS)
See [TERMIUS-SETUP.md](TERMIUS-SETUP.md) for detailed setup

#### Quick SSH Access
```bash
# Direct terminal access
ssh -t root@YOUR_VPS_IP laptop

# Access specific tmux session
ssh -t root@YOUR_VPS_IP laptop-tmux Code
```

## File Structure

```
web-terminal/
├── README.md                  # This file
├── credentials.sh             # VPS configuration (git-ignored)
├── fix-web-terminal.sh        # Main setup/restart script
├── start-web-terminal.sh      # Comprehensive startup script
├── start-ttyd.sh             # Simple ttyd starter
├── index.html                # Enhanced mobile interface
├── mobile-complete.html      # Full mobile interface
├── sessions.html             # Session list page
├── generate-sessions-v2.sh   # Session list generator
├── TERMIUS-SETUP.md         # Termius app setup guide
├── SETUP-INSTRUCTIONS.md    # SSH setup instructions
└── archive/                 # Old/test files

On VPS:
├── /etc/nginx/sites-available/web-terminal  # Nginx config
├── /var/www/terminal/                       # Web files
└── /usr/local/bin/laptop*                   # Helper scripts
```

## Troubleshooting

### Web Terminal Not Loading

1. **Check ttyd is running:**
   ```bash
   ps aux | grep ttyd
   ```

2. **Check SSH tunnel:**
   ```bash
   ps aux | grep autossh
   ```

3. **Test locally:**
   ```bash
   curl -u admin:webterm123 http://localhost:7681/
   ```

4. **Check VPS nginx:**
   ```bash
   ssh vps 'systemctl status nginx'
   ```

### Authentication Issues

- Clear browser cache/cookies
- Try incognito mode
- Use the URL format: `http://admin:webterm123@VPS_IP/`

### Connection Drops

- Normal for idle connections - just refresh
- Your tmux session persists
- Consider using SSH for long sessions

### Mac Sleep Issues

Your Mac going to sleep breaks the connection. Solutions:

1. **Temporary:** Run `caffeinate -d` in a terminal
2. **Permanent:** System Settings → Battery → Prevent sleep when plugged in
3. **Best:** Use SSH access instead of web terminal

## Security Notes

This setup prioritizes convenience for personal use. For production use:

1. **Enable HTTPS** with Let's Encrypt
2. **Use SSH keys** instead of passwords
3. **Restrict IP access** in nginx
4. **Run on non-standard ports**
5. **Use fail2ban** for brute force protection (already configured)

See [SECURITY.md](SECURITY.md) for detailed security analysis.

## Managing Services

### Restart Everything
```bash
./fix-web-terminal.sh
```

### Check Status
```bash
# On Mac
ps aux | grep -E "ttyd|autossh"

# On VPS
ssh vps 'systemctl status nginx'
```

### View Logs
```bash
# ttyd logs
tail -f ~/Library/Logs/web-terminal/ttyd_*.log

# Startup logs
tail -f ~/Library/Logs/web-terminal/startup_*.log
```

## Advanced Configuration

### Change Password
Edit `start-ttyd.sh` and modify the password, then restart:
```bash
launchctl unload ~/Library/LaunchAgents/com.user.ttyd.plist
launchctl load ~/Library/LaunchAgents/com.user.ttyd.plist
```

### Multiple Services
The tunnel also forwards ports 7500-7502 for additional services.

### Custom Domain
1. Point your domain to the VPS
2. Update nginx server_name
3. Install SSL with certbot

## License

This project is for personal use. See LICENSE file for details.