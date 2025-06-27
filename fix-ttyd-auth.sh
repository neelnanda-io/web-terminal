#!/bin/bash

# Fix ttyd authentication by restarting without auth requirement

set -e

echo "🔧 Fixing ttyd authentication..."

# Kill current ttyd process
echo "Stopping current ttyd..."
pkill -f ttyd || true

# Start ttyd without authentication requirement since nginx handles it
echo "Starting ttyd without auth..."
cd /Users/neelnanda/Code/VPS/web-terminal
nohup ttyd -p 7681 -W tmux attach-session -t web-terminal || tmux new-session -s web-terminal > ~/Library/Logs/ttyd.out 2> ~/Library/Logs/ttyd.err &

echo "✅ ttyd restarted without authentication"
echo "The web interface auth is handled by nginx"

# Also update nginx on VPS to remove auth from proxy
ssh vps << 'REMOTE_SCRIPT'
set -e

# Update nginx configuration - simpler approach
cat > /etc/nginx/sites-available/web-terminal << 'EOF'
map $http_upgrade $connection_upgrade {
    default upgrade;
    '' close;
}

server {
    listen 80;
    server_name vps.neelnanda.io 143.110.172.229;

    # Basic auth for the web interface
    auth_basic "Terminal Access";
    auth_basic_user_file /etc/nginx/.htpasswd;

    # Serve static files
    location / {
        root /var/www/terminal;
        index index.html;
        try_files $uri $uri/ =404;
    }

    # WebSocket proxy to ttyd
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
}
EOF

# Test and reload nginx
nginx -t && systemctl reload nginx

echo "✅ Nginx configuration updated!"
REMOTE_SCRIPT