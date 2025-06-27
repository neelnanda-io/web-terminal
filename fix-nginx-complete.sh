#!/bin/bash

# Complete nginx fix for ttyd

set -e

echo "🔧 Fixing nginx configuration completely..."

ssh vps << 'REMOTE_SCRIPT'
set -e

# Backup current config
cp /etc/nginx/sites-available/web-terminal /etc/nginx/sites-available/web-terminal.backup

# Create complete nginx config
cat > /etc/nginx/sites-available/web-terminal << 'EOF'
server {
    listen 80;
    server_name vps.neelnanda.io 143.110.172.229;

    # Proxy all requests to ttyd by default
    location / {
        proxy_pass http://127.0.0.1:7681;
        proxy_http_version 1.1;
        
        # WebSocket support
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Standard headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Pass authentication
        proxy_set_header Authorization $http_authorization;
        proxy_pass_header Authorization;
        
        # Disable buffering for real-time
        proxy_buffering off;
        proxy_request_buffering off;
        
        # Long timeouts for persistent connections
        proxy_connect_timeout 7d;
        proxy_send_timeout 7d;
        proxy_read_timeout 7d;
    }
    
    # Specific routes for our custom pages
    location = /sessions {
        root /var/www/terminal;
        try_files /sessions.html =404;
    }
    
    location = /s {
        return 301 /sessions;
    }
    
    location = /sessions.html {
        root /var/www/terminal;
    }
    
    # Other custom pages if they exist
    location ~ ^/(mobile-terminal\.html|mobile-simple\.html|mobile-complete\.html|mobile-tmux-helper\.html)$ {
        root /var/www/terminal;
        try_files $uri =404;
    }
    
    location = /m {
        root /var/www/terminal;
        try_files /mobile-complete.html =404;
    }
    
    location = /simple {
        root /var/www/terminal;
        try_files /mobile-simple.html =404;
    }
    
    location = /mobile {
        root /var/www/terminal;
        try_files /mobile-terminal.html =404;
    }
}
EOF

# Test and reload
nginx -t
if [ $? -eq 0 ]; then
    systemctl reload nginx
    echo "✅ Nginx configuration fixed!"
else
    echo "❌ Nginx configuration test failed, restoring backup"
    mv /etc/nginx/sites-available/web-terminal.backup /etc/nginx/sites-available/web-terminal
    exit 1
fi
REMOTE_SCRIPT

echo ""
echo "✅ Fixed! The terminal should now work at http://143.110.172.229/"
echo ""
echo "Login with:"
echo "Username: admin"
echo "Password: feet essential wherever principle"