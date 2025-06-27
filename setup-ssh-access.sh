#!/bin/bash

# Setup SSH access to MacBook through VPS
# This creates a jump host configuration

set -e

echo "🔧 Setting up SSH access to your MacBook through VPS..."

# First, ensure the reverse SSH tunnel for port 22 is running
if ! ps aux | grep -q "[s]sh.*2222:localhost:22"; then
    echo "⚠️  Reverse SSH tunnel for port 22 not found!"
    echo "Make sure your autossh/launchd service includes: -R 2222:localhost:22"
    exit 1
fi

echo "✅ Reverse tunnel is running"

# Create SSH key for VPS if it doesn't exist
if [ ! -f ~/.ssh/vps_to_laptop ]; then
    echo "🔑 Generating SSH key for VPS to laptop access..."
    ssh-keygen -t ed25519 -f ~/.ssh/vps_to_laptop -N "" -C "vps-to-laptop"
    
    # Add to authorized_keys
    cat ~/.ssh/vps_to_laptop.pub >> ~/.ssh/authorized_keys
    echo "✅ Added VPS key to authorized_keys"
fi

# Copy the private key to VPS
echo "📤 Copying private key to VPS..."
scp ~/.ssh/vps_to_laptop vps:/root/.ssh/laptop_key
ssh vps "chmod 600 /root/.ssh/laptop_key"

# Setup SSH config on VPS
echo "🔧 Configuring SSH on VPS..."
ssh vps << 'REMOTE_SCRIPT'
set -e

# Create SSH config for easy access
cat > /root/.ssh/config << 'EOF'
Host laptop
    HostName localhost
    Port 2222
    User neelnanda
    IdentityFile ~/.ssh/laptop_key
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF

chmod 600 /root/.ssh/config

# Test connection
echo "🧪 Testing connection from VPS to laptop..."
if ssh -o ConnectTimeout=5 laptop "echo '✅ Connection successful!'" 2>/dev/null; then
    echo "✅ SSH connection from VPS to laptop works!"
else
    echo "❌ Connection failed. Check if SSH is enabled on your Mac."
    echo "To enable: System Preferences → Sharing → Remote Login"
fi

# Create helper script
cat > /usr/local/bin/laptop << 'EOF'
#!/bin/bash
# Quick access to laptop
ssh laptop "$@"
EOF

chmod +x /usr/local/bin/laptop

# Create tmux session helper
cat > /usr/local/bin/laptop-tmux << 'EOF'
#!/bin/bash
# Access specific tmux session on laptop
SESSION="${1:-}"
if [ -z "$SESSION" ]; then
    ssh laptop "tmux ls 2>/dev/null || echo 'No tmux sessions found'"
else
    ssh laptop "tmux attach -t '$SESSION' || tmux new -s '$SESSION'"
fi
EOF

chmod +x /usr/local/bin/laptop-tmux

echo ""
echo "✅ Setup complete on VPS!"
echo ""
echo "Available commands on VPS:"
echo "  laptop              - SSH to your MacBook"
echo "  laptop-tmux         - List tmux sessions"
echo "  laptop-tmux Code    - Attach to Code session"
echo ""
REMOTE_SCRIPT

echo ""
echo "📱 Setting up easy access from other devices..."
echo ""

# Generate a simple connection script
cat > ~/Code/VPS/web-terminal/connect-to-laptop.sh << 'EOF'
#!/bin/bash

# Simple script to connect to laptop via VPS
# Usage: ./connect-to-laptop.sh [session-name]

VPS_HOST="143.110.172.229"
VPS_USER="root"
SESSION="$1"

if [ -z "$SESSION" ]; then
    echo "Connecting to laptop..."
    ssh -t $VPS_USER@$VPS_HOST "laptop"
else
    echo "Connecting to tmux session: $SESSION"
    ssh -t $VPS_USER@$VPS_HOST "laptop-tmux '$SESSION'"
fi
EOF

chmod +x ~/Code/VPS/web-terminal/connect-to-laptop.sh

echo ""
echo "🎯 SETUP COMPLETE!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📱 FOR YOUR ANDROID PHONE (using Termux or JuiceSSH):"
echo ""
echo "1. Add VPS connection:"
echo "   Host: 143.110.172.229"
echo "   User: root"
echo "   Auth: Use your existing VPS SSH key"
echo ""
echo "2. Once connected to VPS, run:"
echo "   laptop              # General SSH access"
echo "   laptop-tmux Code    # Specific tmux session"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💻 FOR YOUR OTHER MACBOOK:"
echo ""
echo "1. One-line connection:"
echo "   ssh -t root@143.110.172.229 laptop"
echo ""
echo "2. Or add to ~/.ssh/config:"
cat << 'EOF'
Host laptop-via-vps
    HostName 143.110.172.229
    User root
    RequestTTY yes
    RemoteCommand laptop

Host laptop-tmux-*
    HostName 143.110.172.229
    User root
    RequestTTY yes
    RemoteCommand laptop-tmux $(echo %n | cut -d- -f3-)
EOF
echo ""
echo "Then use:"
echo "   ssh laptop-via-vps"
echo "   ssh laptop-tmux-Code"
echo "   ssh laptop-tmux-ClaudePhone"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🔐 SECURITY NOTE:"
echo "- Your laptop is only accessible through VPS"
echo "- Uses SSH key authentication"
echo "- Port 2222 is not exposed to internet"
echo ""
echo "⚠️  IMPORTANT: Make sure SSH is enabled on your Mac:"
echo "System Settings → General → Sharing → Remote Login: ON"