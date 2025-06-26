#!/bin/bash

echo "Setting up sleep handling for web terminal..."

# 1. Prevent sleep when on AC power
echo "Configuring power settings..."
sudo pmset -c sleep 0
sudo pmset -c disablesleep 1
echo "✓ Disabled sleep when plugged in"

# 2. Create caffeinate wrapper for ttyd
cat > /Users/neelnanda/Code/VPS/web-terminal/start-ttyd-nosleep.sh << 'EOF'
#!/bin/bash
# Prevent sleep while ttyd is running
exec caffeinate -i /Users/neelnanda/Code/VPS/web-terminal/start-ttyd.sh
EOF
chmod +x /Users/neelnanda/Code/VPS/web-terminal/start-ttyd-nosleep.sh

# 3. Update ttyd launchd to use caffeinate wrapper
cat > ~/Library/LaunchAgents/com.user.ttyd.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.ttyd</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/neelnanda/Code/VPS/web-terminal/start-ttyd-nosleep.sh</string>
    </array>
    <key>WorkingDirectory</key>
    <string>/Users/neelnanda</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
        <key>Crashed</key>
        <true/>
    </dict>
    <key>ThrottleInterval</key>
    <integer>10</integer>
    <key>StandardErrorPath</key>
    <string>/Users/neelnanda/Library/Logs/ttyd.err</string>
    <key>StandardOutPath</key>
    <string>/Users/neelnanda/Library/Logs/ttyd.out</string>
</dict>
</plist>
EOF

# 4. Create wake script using sleepwatcher
brew list sleepwatcher &>/dev/null || brew install sleepwatcher

# Create wake script
cat > ~/.wakeup << 'EOF'
#!/bin/bash
# Log wake event
echo "$(date): System woke up" >> ~/Library/Logs/wake-events.log

# Give network time to reconnect
sleep 5

# Restart services
launchctl kickstart -k gui/$(id -u)/com.user.reversetunnel
launchctl kickstart -k gui/$(id -u)/com.user.ttyd
EOF
chmod +x ~/.wakeup

# 5. Set up sleepwatcher
mkdir -p ~/Library/LaunchAgents
cat > ~/Library/LaunchAgents/com.user.sleepwatcher.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.sleepwatcher</string>
    <key>ProgramArguments</key>
    <array>
        <string>/opt/homebrew/bin/sleepwatcher</string>
        <string>-w</string>
        <string>/Users/neelnanda/.wakeup</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
EOF

# Reload services
echo "Reloading services..."
launchctl unload ~/Library/LaunchAgents/com.user.ttyd.plist 2>/dev/null
launchctl load ~/Library/LaunchAgents/com.user.ttyd.plist
launchctl unload ~/Library/LaunchAgents/com.user.sleepwatcher.plist 2>/dev/null
launchctl load ~/Library/LaunchAgents/com.user.sleepwatcher.plist

echo "✓ Sleep handling setup complete!"
echo ""
echo "What this does:"
echo "- Prevents sleep when plugged in"
echo "- Uses caffeinate to keep ttyd active"
echo "- Auto-restarts services after wake"
echo "- Logs wake events to ~/Library/Logs/wake-events.log"