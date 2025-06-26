#!/bin/bash

# Enhanced Web Terminal Deployment Script
# This script deploys the improved web terminal with mobile controls

set -e

echo "🚀 Deploying Enhanced Web Terminal..."

# Configuration
VPS_HOST="vps"
DOMAIN="vps.neelnanda.io"

# Create deployment package
echo "📦 Creating deployment package..."
tar -czf terminal-deploy.tar.gz index.html terminal.js

# Copy files to VPS
echo "📤 Copying files to VPS..."
scp terminal-deploy.tar.gz $VPS_HOST:/tmp/

# Deploy on VPS
echo "🔧 Deploying on VPS..."
ssh $VPS_HOST << 'REMOTE_SCRIPT'
set -e

# Create web directory
mkdir -p /var/www/terminal
cd /var/www/terminal

# Extract files
tar -xzf /tmp/terminal-deploy.tar.gz
rm /tmp/terminal-deploy.tar.gz

# Install ttyd if not already installed
if ! command -v ttyd &> /dev/null; then
    echo "Installing ttyd..."
    wget -qO ttyd https://github.com/tsl0922/ttyd/releases/latest/download/ttyd.x86_64
    chmod +x ttyd
    mv ttyd /usr/local/bin/
fi

# Create systemd service for ttyd
cat > /etc/systemd/system/ttyd.service << 'EOF'
[Unit]
Description=ttyd - Terminal over HTTP/WebSocket
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/ttyd \
    --writable \
    --port 7681 \
    --credential root:admin \
    --ping-interval 30 \
    --max-clients 10 \
    /usr/bin/tmux attach-session -t main || /usr/bin/tmux new-session -s main
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Update nginx configuration
cat > /etc/nginx/sites-available/web-terminal << 'EOF'
map $http_upgrade $connection_upgrade {
    default upgrade;
    '' close;
}

server {
    listen 80;
    server_name vps.neelnanda.io;

    # Serve static files
    location / {
        root /var/www/terminal;
        index index.html;
        try_files $uri $uri/ =404;
    }

    # WebSocket proxy
    location /ws {
        proxy_pass http://127.0.0.1:7681/ws;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeout settings
        proxy_read_timeout 86400;
        proxy_send_timeout 86400;
        
        # Buffer settings
        proxy_buffering off;
    }

    # Token endpoint for ttyd
    location /token {
        proxy_pass http://127.0.0.1:7681/token;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}

server {
    listen 443 ssl http2;
    server_name vps.neelnanda.io;

    # SSL configuration (Let's Encrypt)
    ssl_certificate /etc/letsencrypt/live/vps.neelnanda.io/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/vps.neelnanda.io/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    # Serve static files
    location / {
        root /var/www/terminal;
        index index.html;
        try_files $uri $uri/ =404;
    }

    # WebSocket proxy
    location /ws {
        proxy_pass http://127.0.0.1:7681/ws;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeout settings
        proxy_read_timeout 86400;
        proxy_send_timeout 86400;
        
        # Buffer settings
        proxy_buffering off;
    }

    # Token endpoint
    location /token {
        proxy_pass http://127.0.0.1:7681/token;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

# Enable site
ln -sf /etc/nginx/sites-available/web-terminal /etc/nginx/sites-enabled/

# Create tmux configuration for better mobile experience
cat > /root/.tmux.conf << 'EOF'
# Enable mouse support
set -g mouse on

# Larger scrollback
set -g history-limit 50000

# Better colors
set -g default-terminal "screen-256color"

# Status bar
set -g status-bg black
set -g status-fg white
set -g status-left '#[fg=green]#S '
set -g status-right '#[fg=yellow]#H %H:%M'

# Window naming
set -g automatic-rename on
set -g allow-rename on

# Start windows at 0
set -g base-index 0
EOF

# Reload services
systemctl daemon-reload
systemctl enable ttyd
systemctl restart ttyd
systemctl reload nginx

echo "✅ Deployment complete!"
echo "📱 Access your terminal at: https://vps.neelnanda.io"
echo "🔑 Default credentials: root / admin"
REMOTE_SCRIPT

# Clean up local package
rm terminal-deploy.tar.gz

echo "
✨ Enhanced Web Terminal Deployed Successfully!

📱 Mobile Features:
- Swipe right to show control panel
- Tap ☰ button to toggle controls
- Use control buttons for keyboard shortcuts
- Auto-hide panel after actions on mobile

🖥️ Desktop Features:  
- Command+Arrow keys work on macOS
- Better keyboard handling
- Persistent control panel

🔗 URL Navigation:
- https://vps.neelnanda.io/Code → tmux window for Code folder
- https://vps.neelnanda.io/Projects → tmux window for Projects folder

🎯 Next Steps:
1. Visit https://vps.neelnanda.io
2. Login with root/admin
3. Test on your mobile device
4. Customize tmux windows as needed
"