#!/bin/bash

# Fix WebSocket authentication passthrough

set -e

echo "🔧 Fixing WebSocket authentication on VPS..."

ssh vps << 'REMOTE_SCRIPT'
set -e

# Update nginx configuration to pass auth to ttyd
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

    # WebSocket proxy to ttyd - pass auth headers
    location /ws {
        # Pass the auth credentials to ttyd
        proxy_pass http://admin:feet%20essential%20wherever%20principle@127.0.0.1:7681/ws;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Remove auth header to prevent double auth
        proxy_set_header Authorization "";
        
        # Timeout settings
        proxy_read_timeout 86400;
        proxy_send_timeout 86400;
        
        # Buffer settings
        proxy_buffering off;
    }

    # Token endpoint for ttyd authentication
    location /token {
        proxy_pass http://admin:feet%20essential%20wherever%20principle@127.0.0.1:7681/token;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Authorization "";
    }
}
EOF

# Test nginx config
nginx -t

# Reload nginx
systemctl reload nginx

echo "✅ WebSocket authentication fixed!"
REMOTE_SCRIPT

echo "✅ Done! The terminal should now connect properly."