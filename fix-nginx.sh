#!/bin/bash

# Fix nginx configuration for ttyd

cat > /etc/nginx/sites-available/web-terminal << 'EOF'
server {
    listen 80;
    server_name _;
    
    # Web terminal - proxy everything to ttyd
    location / {
        auth_basic "Terminal Access";
        auth_basic_user_file /etc/nginx/.htpasswd;
        
        proxy_pass http://localhost:7681;
        proxy_http_version 1.1;
        
        # WebSocket support
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Standard proxy headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts for long-running connections
        proxy_read_timeout 86400;
        proxy_send_timeout 86400;
        
        # Disable buffering for real-time updates
        proxy_buffering off;
    }
}
EOF

# Test and reload nginx
nginx -t && systemctl reload nginx

echo "Nginx configuration updated!"