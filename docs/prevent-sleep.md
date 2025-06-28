# Preventing Sleep Issues for Web Terminal

## The Problem

When your MacBook goes to sleep:
1. Network connections are dropped (breaking the SSH tunnel)
2. Background processes are suspended (stopping ttyd)
3. The web terminal becomes inaccessible

## Solutions

### Option 1: Prevent Sleep When Plugged In (Recommended)

**System Settings:**
1. Open System Settings → Battery → Power Adapter
2. Turn on "Prevent automatic sleeping when the display is off"
3. Set "Turn display off after" to your preference (display can turn off safely)

**Terminal command alternative:**
```bash
sudo pmset -c sleep 0
sudo pmset -c disablesleep 1
```

### Option 2: Use caffeinate for Specific Processes

Create a modified launchd service that prevents sleep:

```bash
# Create a wrapper script
cat > ~/Code/VPS/web-terminal/start-ttyd-nosleep.sh << 'EOF'
#!/bin/bash
# Prevent sleep while ttyd is running
exec caffeinate -i /Users/neelnanda/Code/VPS/web-terminal/start-ttyd.sh
EOF

chmod +x ~/Code/VPS/web-terminal/start-ttyd-nosleep.sh
```

Then update the launchd plist to use this wrapper.

### Option 3: Power Assertions (More Advanced)

Install `sleepwatcher` to run scripts on sleep/wake:
```bash
brew install sleepwatcher

# Create wake script to restart services
cat > ~/.wakeup << 'EOF'
#!/bin/bash
# Restart services after wake
launchctl unload ~/Library/LaunchAgents/com.user.reversetunnel.plist
launchctl load ~/Library/LaunchAgents/com.user.reversetunnel.plist
launchctl unload ~/Library/LaunchAgents/com.user.ttyd.plist
launchctl load ~/Library/LaunchAgents/com.user.ttyd.plist
EOF

chmod +x ~/.wakeup
```

### Option 4: Run Services on VPS Instead (Most Reliable)

For critical always-on access, consider running a persistent shell on the VPS itself:
```bash
# On VPS, install ttyd
ssh vps "apt-get install -y ttyd"

# Create a service that runs ttyd directly on VPS
ssh vps "ttyd -p 7682 -c admin:password bash"
```

## Quick Fix for Current Setup

Add auto-recovery to your services: