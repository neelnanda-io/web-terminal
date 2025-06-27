#!/bin/bash

# Final nginx configuration with all interfaces

set -e

echo "🔧 Setting up final nginx configuration..."

ssh vps << 'REMOTE_SCRIPT'
set -e

# Create complete nginx config
cat > /etc/nginx/sites-available/web-terminal << 'EOF'
server {
    listen 80;
    server_name vps.neelnanda.io 143.110.172.229;

    # Serve our custom interfaces
    location = /mobile-terminal.html {
        root /var/www/terminal;
    }
    
    location = /mobile-simple.html {
        root /var/www/terminal;
    }
    
    location = /mobile-complete.html {
        root /var/www/terminal;
    }
    
    # Short URLs
    location = /m {
        rewrite ^/m$ /mobile-complete.html permanent;
    }
    
    location = /simple {
        rewrite ^/simple$ /mobile-simple.html permanent;
    }
    
    location = /mobile {
        rewrite ^/mobile$ /mobile-terminal.html permanent;
    }
    
    # Other static files
    location ~ ^/(index\.html|terminal\.js|debug-terminal\.html|test-connection\.html)$ {
        root /var/www/terminal;
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
        
        # Timeouts
        proxy_connect_timeout 7d;
        proxy_send_timeout 7d;
        proxy_read_timeout 7d;
    }
}
EOF

# Test and reload
nginx -t && systemctl reload nginx

echo "✅ Configuration complete!"
echo ""
echo "📱 Mobile Interfaces:"
echo "- http://143.110.172.229/m - Complete mobile interface (BEST)"
echo "- http://143.110.172.229/simple - Simple copy buttons"
echo "- http://143.110.172.229/ - Standard ttyd"
REMOTE_SCRIPT