# Web Terminal Access - Complete Documentation

## 🎯 Purpose

This setup allows you to access and control your MacBook from anywhere in the world through a web browser. You can edit files, run commands, and manage your development environment remotely by visiting a simple URL.

## 🌐 Quick Access

**URL: http://143.110.172.229/**
- **Username**: admin  
- **Password**: feet essential wherever principle

This gives you a full terminal session running on your MacBook, accessible from any device with a web browser.

## 🏗️ Architecture Overview

```
[Your Phone/Tablet/Other Laptop] 
            ↓ (HTTPS/HTTP)
    [VPS - 143.110.172.229]
     - nginx (reverse proxy)
     - Basic authentication
            ↓ (SSH Reverse Tunnel)
    [Your MacBook at Home]
     - ttyd (web terminal server)
     - tmux (persistent sessions)
     - autossh (maintains tunnel)
```

### Components Explained

1. **ttyd**: A lightweight terminal emulator that serves a terminal session over HTTP
2. **tmux**: Terminal multiplexer that keeps your session alive even if you disconnect
3. **autossh**: Maintains the SSH reverse tunnel, auto-reconnecting if it drops
4. **nginx**: Web server on VPS that handles authentication and proxies to ttyd
5. **Reverse SSH Tunnel**: Creates a secure connection from your laptop to the VPS

## ⚡ Critical: Preventing Sleep Issues

**Your MacBook MUST stay awake for the web terminal to work!**

### Permanent Solution (Recommended)

Disable sleep when your MacBook is plugged in:

```bash
# Run these commands once (requires admin password)
sudo pmset -c sleep 0
sudo pmset -c disablesleep 1
```

Or via System Settings:
1. Open System Settings → Battery → Power Adapter
2. Turn ON "Prevent automatic sleeping when the display is off"
3. The display can still turn off - only sleep is prevented

### Why This Matters

When your MacBook sleeps:
- Network connections drop (breaking the SSH tunnel)
- Background processes pause (stopping ttyd)
- The web terminal becomes completely inaccessible
- You cannot wake it remotely

With sleep disabled while charging:
- Your MacBook stays accessible 24/7 when plugged in
- The tunnel maintains connection
- You can always reach your development environment
- Battery life is unaffected when unplugged

## 📁 File Structure

```
/Users/neelnanda/Code/VPS/web-terminal/
├── README-COMPREHENSIVE.md     # This file
├── start-ttyd.sh              # Main script that starts ttyd
├── project_memory.md          # Project overview
└── [other setup scripts]

~/Library/LaunchAgents/
├── com.user.ttyd.plist        # Auto-starts ttyd on boot
└── com.user.reversetunnel.plist  # Auto-starts SSH tunnel

~/Library/Logs/
├── ttyd.out                   # ttyd output logs
├── ttyd.err                   # ttyd error logs
├── reversetunnel.out          # Tunnel output logs
└── reversetunnel.err          # Tunnel error logs
```

## 🚀 Service Management

### Starting/Stopping Services

```bash
# Check if services are running
ps aux | grep ttyd
ps aux | grep autossh

# Restart ttyd (web terminal)
launchctl unload ~/Library/LaunchAgents/com.user.ttyd.plist
launchctl load ~/Library/LaunchAgents/com.user.ttyd.plist

# Restart SSH tunnel
launchctl unload ~/Library/LaunchAgents/com.user.reversetunnel.plist
launchctl load ~/Library/LaunchAgents/com.user.reversetunnel.plist

# Quick restart both after sleep
launchctl kickstart -k gui/$(id -u)/com.user.reversetunnel
launchctl kickstart -k gui/$(id -u)/com.user.ttyd
```

### Checking Service Status

```bash
# View service status
launchctl list | grep -E "ttyd|reversetunnel"

# Check logs for errors
tail -f ~/Library/Logs/ttyd.err
tail -f ~/Library/Logs/reversetunnel.err

# Test locally
curl -u admin:"feet essential wherever principle" http://localhost:7681
```

## 🔧 Configuration Details

### ttyd Configuration (start-ttyd.sh)

```bash
#!/bin/bash
# Located at: /Users/neelnanda/Code/VPS/web-terminal/start-ttyd.sh

# Configuration
TMUX_SESSION="web-terminal"     # Name of tmux session
TTYD_PORT=7681                   # Port ttyd listens on
TTYD_CREDENTIAL="admin:feet essential wherever principle"  # Auth credentials

# ttyd starts with these options:
# -p 7681                        # Port number
# -c "user:pass"                 # Basic authentication
# -t "titleFixed=Neel's Terminal" # Browser tab title
# -W                             # Allow write (input)
```

### SSH Tunnel Configuration

The reverse tunnel forwards these ports:
- **2222**: SSH access to laptop through VPS
- **7500-7502**: Additional service ports
- **7681**: ttyd web terminal

### nginx Configuration (on VPS)

```nginx
server {
    listen 80;
    location / {
        auth_basic "Terminal Access";
        auth_basic_user_file /etc/nginx/.htpasswd;
        proxy_pass http://localhost:7681;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 86400;
    }
}
```

## 📱 Using the Web Terminal

### Basic Terminal Usage

Once connected, you have a full terminal with tmux:

**Tmux Shortcuts** (Ctrl+B is the prefix):
- `Ctrl+B C` - Create new window
- `Ctrl+B 0-9` - Switch to window number
- `Ctrl+B %` - Split pane vertically  
- `Ctrl+B "` - Split pane horizontally
- `Ctrl+B ←→↑↓` - Navigate between panes
- `Ctrl+B D` - Detach session (it keeps running)
- `Ctrl+B [` - Enter scroll mode (q to exit)

### Mobile Tips

- Works on iOS Safari, Chrome, Android browsers
- Use a Bluetooth keyboard for better typing
- Pinch to zoom for readability
- Consider landscape orientation
- Copy/paste may require long-press

### Session Persistence

Your tmux session named "web-terminal" persists even when:
- You close the browser
- Network connection drops  
- You disconnect for days
- Services restart

Just reconnect to continue where you left off!

## 🛡️ Security Considerations

### Current Security Model

**Optimized for convenience with basic security**:
- HTTP Basic Authentication (username/password)
- Password transmitted in base64 (not encrypted)
- No HTTPS encryption by default
- Full system access once authenticated
- Publicly accessible from any IP

### Security Trade-offs

**Current Setup Pros**:
- Simple password access from any device
- No SSH keys needed on client devices
- Works on any modern browser
- Easy to share access if needed

**Current Setup Cons**:
- Password can be intercepted on untrusted networks
- No encryption of terminal session
- Basic auth is minimal security
- Anyone with password has full system access

### Optional Security Enhancements

1. **Add HTTPS with Let's Encrypt** (Recommended)
   ```bash
   ssh vps
   apt install certbot python3-certbot-nginx
   certbot --nginx -d your-domain.com
   ```
   - Pros: Encrypted connection, modern browser compatibility
   - Cons: Requires domain name

2. **IP Whitelisting**
   ```nginx
   location / {
       allow 1.2.3.4;  # Your home IP
       allow 5.6.7.8;  # Your work IP  
       deny all;
       # ... rest of config
   }
   ```
   - Pros: Only specified IPs can connect
   - Cons: Can't access from random locations

3. **Stronger Authentication**
   - Use longer passwords
   - Implement 2FA with nginx modules
   - Use client certificates

4. **VPN Instead**
   - Set up WireGuard on VPS
   - Connect via VPN, then access locally
   - Most secure but less convenient

## 🔍 Troubleshooting Guide

### Terminal Not Accessible

1. **Check if MacBook is awake**
   - If at home, check if it's sleeping
   - Run sleep prevention commands if needed

2. **Verify services are running**
   ```bash
   # On MacBook
   ps aux | grep ttyd
   ps aux | grep autossh
   ```

3. **Test local access first**
   ```bash
   # On MacBook
   curl -u admin:"feet essential wherever principle" http://localhost:7681
   ```

4. **Check tunnel on VPS**
   ```bash
   ssh vps "ss -tlnp | grep 7681"
   # Should show LISTEN on port 7681
   ```

5. **Restart everything**
   ```bash
   # On MacBook
   launchctl unload ~/Library/LaunchAgents/com.user.reversetunnel.plist
   launchctl unload ~/Library/LaunchAgents/com.user.ttyd.plist
   launchctl load ~/Library/LaunchAgents/com.user.reversetunnel.plist
   launchctl load ~/Library/LaunchAgents/com.user.ttyd.plist
   ```

### Common Issues

**"502 Bad Gateway" error**
- ttyd is not running on laptop
- Check `~/Library/Logs/ttyd.err`

**"Connection refused"**
- SSH tunnel is down
- Check `~/Library/Logs/reversetunnel.err`

**Blank screen or doesn't load**
- Browser blocking WebSocket
- Try different browser or disable extensions

**Session seems frozen**
- tmux session might be stuck
- SSH to laptop: `tmux kill-session -t web-terminal`

## 🚧 Maintenance Tasks

### Regular Maintenance

```bash
# Check disk space (logs can grow)
df -h
du -sh ~/Library/Logs/

# Rotate logs if needed
echo > ~/Library/Logs/ttyd.out
echo > ~/Library/Logs/reversetunnel.out

# Update tmux session
tmux attach -t web-terminal
# Make any needed changes
Ctrl+B D  # Detach
```

### Monitoring Health

```bash
# Create health check script
cat > ~/Code/VPS/web-terminal/health-check.sh << 'EOF'
#!/bin/bash
echo "=== Web Terminal Health Check ==="
echo "Date: $(date)"
echo ""
echo "ttyd process:"
ps aux | grep ttyd | grep -v grep || echo "NOT RUNNING!"
echo ""
echo "autossh process:"  
ps aux | grep autossh | grep -v grep || echo "NOT RUNNING!"
echo ""
echo "Local test:"
curl -s -u admin:"feet essential wherever principle" http://localhost:7681 > /dev/null && echo "✓ Working" || echo "✗ Failed"
echo ""
echo "VPS tunnel test:"
ssh vps "curl -s http://localhost:7681" > /dev/null && echo "✓ Tunnel active" || echo "✗ Tunnel down"
EOF

chmod +x ~/Code/VPS/web-terminal/health-check.sh
```

## 📚 Additional Resources

### Understanding the Technology

**tmux (Terminal Multiplexer)**
- Manages multiple terminal sessions
- Sessions persist when you disconnect
- Can split screen, multiple windows
- [tmux cheat sheet](https://tmuxcheatsheet.com/)

**ttyd (Terminal Over Web)**
- Lightweight (~500KB binary)
- WebSocket-based communication
- Supports file upload/download
- [ttyd GitHub](https://github.com/tsl0922/ttyd)

**SSH Reverse Tunneling**
- Creates outbound connection from laptop to VPS
- VPS can then forward traffic back through tunnel
- Bypasses NAT/firewall restrictions
- Maintained by autossh for reliability

### Related Commands

```bash
# Check all forwarded ports
ssh vps "ss -tlnp | grep sshd"

# View active SSH connections
ssh vps "ss -tnp | grep :22"

# Monitor bandwidth usage
ssh vps "apt install iftop && iftop"

# See terminal dimensions
echo "Lines: $LINES, Columns: $COLUMNS"
```

## 🎉 Summary

You now have:
1. **24/7 terminal access** to your MacBook from anywhere
2. **Persistent tmux sessions** that survive disconnections  
3. **Simple password access** from any device
4. **Automatic startup** of all services
5. **Sleep prevention** to maintain availability

The system is designed for maximum convenience while providing basic security. The terminal gives you full access to your MacBook, so you can code, edit files, run builds, and manage your development environment from anywhere in the world.

Remember: Keep your MacBook plugged in and prevent sleep for uninterrupted access!