# Quick Sleep Fix for Web Terminal

## Immediate Solution (No Admin Password Required)

### 1. Keep Mac Awake When You Need Terminal Access

**Manual method** (when you know you'll need access):
```bash
# In any terminal window, run:
caffeinate -d

# This prevents sleep until you press Ctrl+C
# Leave it running in a background terminal
```

**Automatic method** (always prevents sleep when plugged in):
```bash
# Check current settings
pmset -g

# If you have admin access:
sudo pmset -c sleep 0
```

### 2. Better Alternative: Run Terminal on VPS

Instead of tunneling back to your laptop, run a terminal directly on the VPS:

```bash
# Quick setup (run once):
ssh vps << 'EOF'
# Install ttyd on VPS
curl -L https://github.com/tsl0922/ttyd/releases/download/v1.7.7/ttyd.x86_64 -o /usr/local/bin/ttyd
chmod +x /usr/local/bin/ttyd

# Create a tmux session on VPS
tmux new-session -d -s vps-terminal

# Create systemd service
cat > /etc/systemd/system/ttyd-vps.service << 'SERVICE'
[Unit]
Description=ttyd VPS terminal
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/ttyd -p 7682 -c admin:feet essential wherever principle tmux attach -t vps-terminal
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE

systemctl enable ttyd-vps
systemctl start ttyd-vps
ufw allow 7682
EOF

echo "VPS terminal available at http://143.110.172.229:7682"
```

This gives you a terminal that:
- Always works (VPS never sleeps)
- Doesn't depend on your laptop
- Can run long tasks independently
- Still accessible with same password

### 3. Current Setup Recovery

If your laptop went to sleep and terminal stopped working:

```bash
# Option A: Restart services manually
launchctl kickstart -k gui/$(id -u)/com.user.reversetunnel
launchctl kickstart -k gui/$(id -u)/com.user.ttyd

# Option B: Full restart (more reliable)
launchctl unload ~/Library/LaunchAgents/com.user.reversetunnel.plist
launchctl unload ~/Library/LaunchAgents/com.user.ttyd.plist
launchctl load ~/Library/LaunchAgents/com.user.reversetunnel.plist
launchctl load ~/Library/LaunchAgents/com.user.ttyd.plist
```

## Recommendations

1. **For occasional use**: Just run `caffeinate -d` when needed
2. **For frequent use**: Set up the VPS terminal (doesn't depend on laptop)
3. **For always-on**: Run the sleep handling setup script

The VPS terminal option is most reliable since it doesn't depend on your laptop being awake or connected.