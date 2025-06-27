#!/bin/bash

# Add route for simple mobile interface

set -e

echo "🔧 Adding route for simple mobile interface..."

ssh vps << 'REMOTE_SCRIPT'
set -e

# Update nginx config to add new route
cat > /etc/nginx/sites-available/web-terminal << 'EOF'
server {
    listen 80;
    server_name vps.neelnanda.io 143.110.172.229;

    # Serve our custom mobile interfaces
    location = /mobile-terminal.html {
        root /var/www/terminal;
        try_files $uri =404;
    }
    
    location = /mobile-simple.html {
        root /var/www/terminal;
        try_files $uri =404;
    }
    
    location = /mobile {
        rewrite ^/mobile$ /mobile-terminal.html permanent;
    }
    
    location = /simple {
        rewrite ^/simple$ /mobile-simple.html permanent;
    }
    
    # Serve our enhanced interface files
    location ~ ^/(index\.html|terminal\.js|debug-terminal\.html|test-connection\.html)$ {
        root /var/www/terminal;
        try_files $uri =404;
    }
    
    # Everything else goes to ttyd
    location / {
        proxy_pass http://127.0.0.1:7681;
        proxy_http_version 1.1;
        
        # WebSocket headers
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Standard headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Pass auth headers
        proxy_set_header Authorization $http_authorization;
        proxy_pass_header Authorization;
        
        # Disable buffering
        proxy_buffering off;
        proxy_request_buffering off;
        
        # Timeouts for long connections
        proxy_connect_timeout 7d;
        proxy_send_timeout 7d;
        proxy_read_timeout 7d;
    }
}
EOF

# Test and reload
nginx -t && systemctl reload nginx

echo "✅ Routes updated!"
echo ""
echo "Available interfaces:"
echo "- http://143.110.172.229/ - Standard ttyd"
echo "- http://143.110.172.229/simple - Simple mobile helper (RECOMMENDED)"
echo "- http://143.110.172.229/mobile - Complex interface (buttons don't work)"
REMOTE_SCRIPT