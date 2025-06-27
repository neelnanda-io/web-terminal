# Android SSH Setup for Laptop Access

## Recommended Apps

### 1. JuiceSSH (Easiest)
- Install from Play Store
- Free version works fine

### 2. Termux (More powerful)
- Install from F-Droid (NOT Play Store version)
- Full Linux environment

## JuiceSSH Setup (Recommended)

1. **Create VPS Connection:**
   - Tap + to add new connection
   - Nickname: `My Laptop`
   - Type: `SSH`
   - Address: `143.110.172.229`
   - Identity: Create new or use existing
   - Username: `root`

2. **Add SSH Key (if needed):**
   - Go to Identities
   - Create new identity
   - Generate new key or paste existing

3. **Create Quick Actions:**
   After connecting to VPS, save these as snippets:
   - `laptop` - Direct SSH to MacBook
   - `laptop-tmux` - List tmux sessions
   - `laptop-tmux Code` - Connect to Code session

## Termux Setup

```bash
# 1. Install SSH
pkg update && pkg install openssh

# 2. Generate SSH key
ssh-keygen -t ed25519 -N ""

# 3. Copy your public key
cat ~/.ssh/id_ed25519.pub
# Copy this output

# 4. Add to VPS (on your Mac terminal):
ssh root@143.110.172.229 "echo 'YOUR_PUBLIC_KEY' >> ~/.ssh/authorized_keys"

# 5. Create shortcuts
cat > ~/l << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
ssh -t root@143.110.172.229 laptop
EOF

cat > ~/lt << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
ssh -t root@143.110.172.229 "laptop-tmux $1"
EOF

chmod +x ~/l ~/lt

# Usage:
./l          # Connect to laptop
./lt         # List tmux sessions
./lt Code    # Connect to Code session
```

## Even Simpler: Bookmark These Commands

Save these in your SSH app:

1. **General Access:**
   ```
   ssh -t root@143.110.172.229 laptop
   ```

2. **Specific Sessions:**
   ```
   ssh -t root@143.110.172.229 "laptop-tmux Code"
   ssh -t root@143.110.172.229 "laptop-tmux ClaudePhone"
   ssh -t root@143.110.172.229 "laptop-tmux VPS"
   ```

## Tips for Mobile

- **Screen Size**: Use pinch-to-zoom in JuiceSSH
- **Keyboard**: Get a Bluetooth keyboard for serious work
- **Quick Access**: Save connections as home screen shortcuts
- **Copy/Paste**: Long-press for menu in most SSH apps

## Troubleshooting

If connection fails:
1. Check if you can connect to VPS first
2. Make sure your MacBook is awake and SSH is enabled
3. The reverse tunnel might need restarting on your Mac