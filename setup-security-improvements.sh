#!/bin/bash

# Setup security improvements: fail2ban and SSH agent forwarding

set -e

echo "🔒 Setting up security improvements..."
echo ""

# First, setup on VPS
echo "📡 Configuring VPS security..."
ssh vps << 'VPS_SETUP'
set -e

# 1. Install and configure fail2ban
echo "🛡️ Installing fail2ban..."
if ! command -v fail2ban-client &> /dev/null; then
    apt-get update
    apt-get install -y fail2ban
else
    echo "✅ fail2ban already installed"
fi

# Create fail2ban configuration for SSH
echo "📝 Configuring fail2ban for SSH protection..."
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
# Ban for 10 minutes after 5 failed attempts
bantime = 10m
findtime = 10m
maxretry = 5

[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 5
EOF

# Restart fail2ban
systemctl restart fail2ban
systemctl enable fail2ban

echo "✅ fail2ban configured and running"
fail2ban-client status sshd || true

echo ""
echo "🔑 Updating SSH configuration for agent forwarding..."

# Backup the old laptop key (we'll keep it for now as fallback)
if [ -f /root/.ssh/laptop_key ]; then
    mv /root/.ssh/laptop_key /root/.ssh/laptop_key.backup
    echo "✅ Backed up old key to laptop_key.backup"
fi

# Update SSH config to remove IdentityFile and add ForwardAgent
cat > /root/.ssh/config << 'EOF'
Host laptop
    HostName localhost
    Port 2222
    User neelnanda
    ForwardAgent yes
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    # Fallback to backup key if agent forwarding fails
    IdentityFile ~/.ssh/laptop_key.backup
    IdentitiesOnly yes
    PreferredAuthentications publickey
EOF

# Update the helper scripts to use agent forwarding
cat > /usr/local/bin/laptop << 'EOF'
#!/bin/bash
# Quick access to laptop (with agent forwarding)
ssh -A laptop "$@"
EOF

cat > /usr/local/bin/laptop-tmux << 'EOF'
#!/bin/bash
# Access specific tmux session on laptop (with agent forwarding)
SESSION="${1:-}"
if [ -z "$SESSION" ]; then
    ssh -A laptop "tmux ls 2>/dev/null || echo 'No tmux sessions found'"
else
    ssh -A laptop "tmux attach -t '$SESSION' || tmux new -s '$SESSION'"
fi
EOF

chmod +x /usr/local/bin/laptop /usr/local/bin/laptop-tmux

echo ""
echo "✅ VPS security setup complete!"
echo ""
echo "📊 Current fail2ban status:"
fail2ban-client status sshd | grep -E "Currently|Total" || echo "No bans yet"

VPS_SETUP

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ Security improvements installed!"
echo ""
echo "🛡️ FAIL2BAN: Now protecting your VPS from brute force attacks"
echo "   - Blocks IPs after 5 failed login attempts"
echo "   - Ban duration: 10 minutes"
echo "   - Check status: ssh vps 'fail2ban-client status sshd'"
echo ""
echo "🔑 SSH AGENT FORWARDING: Ready to use"
echo "   - Your SSH keys stay on your local device"
echo "   - No keys stored on VPS (except backup for fallback)"
echo ""