#!/bin/bash

# Setup nginx to proxy ALL requests to ttyd, not just WebSocket

set -e

echo "🔧 Setting up full ttyd proxy..."

ssh vps << 'REMOTE_SCRIPT'
set -e

# Create a simpler nginx config that proxies everything to ttyd
cat > /etc/nginx/sites-available/web-terminal << 'EOF'
server {
    listen 80;
    server_name vps.neelnanda.io 143.110.172.229;

    # Basic auth handled by ttyd itself
    
    # Proxy everything to ttyd
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

echo "✅ ttyd proxy configured!"
echo ""
echo "Visit http://143.110.172.229 to access ttyd's built-in interface"
echo "Username: admin"
echo "Password: feet essential wherever principle"
REMOTE_SCRIPT