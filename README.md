# Web Terminal Access System

> ⚠️ **SECURITY WARNING**: This system provides remote command execution access. Read [SECURITY.md](SECURITY.md) before deploying.

> 📖 **For complete documentation, see [README-COMPREHENSIVE.md](README-COMPREHENSIVE.md)**

## Overview

This project creates a web-accessible terminal interface to your local machine through a VPS proxy. It allows you to access your development environment from any device with a web browser.

## Quick Start

### Prerequisites

- macOS laptop (local machine)
- Linux VPS with public IP
- SSH key-based access to VPS
- Homebrew installed

### Installation

1. **Clone and configure:**
   ```bash
   git clone <repository-url>
   cd web-terminal
   cp credentials.example.sh credentials.sh
   # Edit credentials.sh with your settings
   ```

2. **Install dependencies:**
   ```bash
   brew install ttyd tmux
   ```

3. **Run tests:**
   ```bash
   python3 tests/test_setup.py
   ./tests/test_connection.sh
   ```

4. **Start services:**
   ```bash
   ./start-ttyd.sh
   ```

## What This Does

This setup provides a web-based interface to a tmux session running on your laptop. You can:
- Run commands on your laptop from your phone, tablet, or another computer
- Access your development environment from anywhere
- Maintain persistent sessions that survive disconnections
- Share terminal access with others (if you give them the password)

## How It Works

1. **ttyd** runs on your laptop, serving a tmux session over HTTP on port 7681
2. The **reverse SSH tunnel** forwards port 7681 from your laptop to the VPS
3. **nginx** on the VPS proxies web requests to the tunneled ttyd port
4. **Basic authentication** protects access with a username/password

## Managing the Service

### On Your Laptop

```bash
# Check if ttyd is running
ps aux | grep ttyd

# View ttyd logs
tail -f ~/Library/Logs/ttyd.out
tail -f ~/Library/Logs/ttyd.err

# Restart ttyd service
launchctl unload ~/Library/LaunchAgents/com.user.ttyd.plist
launchctl load ~/Library/LaunchAgents/com.user.ttyd.plist

# Manually start ttyd (for testing)
cd /Users/neelnanda/Code/VPS/web-terminal
./start-ttyd.sh
```

### Tmux Commands (in the web terminal)

- **Create new window**: Ctrl+B, then C
- **Switch windows**: Ctrl+B, then 0-9
- **Split pane horizontally**: Ctrl+B, then %
- **Split pane vertically**: Ctrl+B, then "
- **Switch panes**: Ctrl+B, then arrow keys
- **Detach session**: Ctrl+B, then D

### On the VPS

```bash
# Check nginx status
ssh vps "systemctl status nginx"

# View nginx logs
ssh vps "tail -f /var/log/nginx/access.log"
ssh vps "tail -f /var/log/nginx/error.log"

# Restart nginx
ssh vps "systemctl restart nginx"
```

## Security Considerations

⚠️ **IMPORTANT**: This setup prioritizes convenience for personal use. See [SECURITY.md](SECURITY.md) for detailed security analysis and recommendations.

**Current Setup**:
- Basic HTTP authentication
- Full command execution access
- Suitable for personal use only

**Optional Security Improvements**:

1. **Enable HTTPS with Let's Encrypt**
   ```bash
   ssh vps
   apt install certbot python3-certbot-nginx
   certbot --nginx -d your-domain.com
   ```
   - Pro: Encrypted connection
   - Con: Requires domain name

2. **Restrict IP Access**
   - Add IP whitelist to nginx config
   - Pro: Only specific IPs can connect
   - Con: Can't access from random locations

3. **Use SSH Instead**
   - Direct SSH is more secure than web terminal
   - Pro: Built-in encryption and authentication
   - Con: Requires SSH client on all devices

## Important: Sleep Issues

⚠️ **Your Mac going to sleep will break the web terminal!**

### Quick Fixes:

1. **Prevent sleep temporarily** (run in any terminal):
   ```bash
   caffeinate -d
   # Leave running while you need access
   ```

2. **Prevent sleep when plugged in**:
   - System Settings → Battery → Power Adapter
   - Turn on "Prevent automatic sleeping when the display is off"

3. **If terminal stops working after sleep**:
   ```bash
   # Restart services
   launchctl kickstart -k gui/$(id -u)/com.user.reversetunnel
   launchctl kickstart -k gui/$(id -u)/com.user.ttyd
   ```

See `SLEEP-FIX.md` for more solutions, including running terminal directly on VPS (most reliable).

## Troubleshooting

**Can't access the terminal?**

1. Check if ttyd is running on laptop:
   ```bash
   ps aux | grep ttyd
   ```

2. Check if tunnel is active:
   ```bash
   ssh vps "ss -tlnp | grep 7681"
   ```

3. Test locally first:
   ```bash
   curl -u admin:"feet essential wherever principle" http://localhost:7681
   ```

4. Check nginx on VPS:
   ```bash
   ssh vps "curl -u admin:'feet essential wherever principle' http://localhost:7681"
   ```

**Terminal not responding?**
- The tmux session might be stuck
- SSH to laptop and run: `tmux kill-session -t web-terminal`
- The service will create a new session automatically

**Connection drops frequently?**
- This is normal for long idle periods
- Just refresh the browser to reconnect
- Your tmux session persists even when disconnected

## Files and Locations

**On Laptop:**
- Start script: `/Users/neelnanda/Code/VPS/web-terminal/start-ttyd.sh`
- Service file: `~/Library/LaunchAgents/com.user.ttyd.plist`
- Logs: `~/Library/Logs/ttyd.{out,err}`

**On VPS:**
- Nginx config: `/etc/nginx/sites-available/web-terminal`
- Password file: `/etc/nginx/.htpasswd`
- Nginx logs: `/var/log/nginx/`

## Advanced Usage

### Running Multiple Services

You can run other web services on ports 7500-7502 and access them through the VPS:
- http://143.110.172.229:7500
- http://143.110.172.229:7501
- http://143.110.172.229:7502

### Customizing ttyd

Edit `/Users/neelnanda/Code/VPS/web-terminal/start-ttyd.sh` to:
- Change the terminal title
- Modify authentication credentials
- Adjust terminal settings

### Mobile Access Tips

- The terminal works well on mobile browsers
- Use a Bluetooth keyboard for better typing
- Pinch to zoom for better visibility
- Consider using a terminal app instead for better experience

## Enhanced Mobile Interface (NEW!)

The web terminal now includes a mobile-optimized control panel for easier use on touch devices.

### Control Panel Features

**Access Methods:**
- Tap the **☰** button in the top-left corner
- Swipe right from the left edge (mobile only)
- Panel auto-hides after button press on mobile

### Available Controls

**Navigation Buttons:**
- **↑ ↓ ← →** - Arrow keys for cursor movement
- **Home/End** - Jump to line start/end
- **Tab** - Tab completion
- **Esc** - Escape key
- **Enter** - Enter/Return
- **⌫ Back** - Backspace

**Control Keys:**
- **Ctrl+C** - Interrupt/cancel current process
- **Ctrl+D** - Exit/logout
- **Ctrl+Z** - Suspend current process
- **Ctrl+L** - Clear screen

**Tmux Controls:**
- **Next Win** - Next tmux window (Ctrl+B, N)
- **Prev Win** - Previous window (Ctrl+B, P)  
- **New Win** - Create new window (Ctrl+B, C)
- **Detach** - Detach session (Ctrl+B, D)
- **Scroll Mode** - Enter scroll mode (Ctrl+B, [)
- **Kill Pane** - Close pane (Ctrl+B, X)

**Quick Commands:**
- **List Files** - Runs `ls -la`
- **Current Dir** - Runs `pwd`
- **Clear** - Clears terminal
- **List Sessions** - Shows tmux sessions

### Cross-Platform Keyboard Fixes

**macOS Command Key Support:**
- **Cmd+←** - Jump to line start (Home)
- **Cmd+→** - Jump to line end (End)
- **Cmd+Backspace** - Delete to line start
- **Cmd+C/V** - Copy/Paste support

### URL-Based Window Navigation

Access specific tmux windows directly via URL:
- `http://143.110.172.229/Code` - Opens Code window
- `http://143.110.172.229/Projects` - Opens Projects window
- `http://143.110.172.229/Documents` - Opens Documents window

This allows opening multiple browser tabs for different tmux windows.