#!/bin/bash

# Fix nginx deployment - remove SSL config for now

set -e

echo "🔧 Fixing nginx configuration on VPS..."

ssh vps << 'REMOTE_SCRIPT'
set -e

# Update nginx configuration without SSL
cat > /etc/nginx/sites-available/web-terminal << 'EOF'
map $http_upgrade $connection_upgrade {
    default upgrade;
    '' close;
}

server {
    listen 80;
    server_name vps.neelnanda.io 143.110.172.229;

    # Basic auth
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

    # Token endpoint for ttyd authentication
    location /token {
        proxy_pass http://127.0.0.1:7681/token;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

# Test nginx config
nginx -t

# Reload nginx
systemctl reload nginx

echo "✅ Nginx configuration fixed!"
REMOTE_SCRIPT

echo "✅ Done! Visit http://143.110.172.229 or http://vps.neelnanda.io"