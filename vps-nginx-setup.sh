#!/bin/bash

# VPS nginx configuration for web terminal

# Install nginx if not present
apt-get update
apt-get install -y nginx apache2-utils

# Create password file for basic auth
htpasswd -bc /etc/nginx/.htpasswd admin "feet essential wherever principle"

# Create nginx configuration for web terminal
cat > /etc/nginx/sites-available/web-terminal << 'EOF'
server {
    listen 80;
    server_name _;
    
    # Web terminal on /terminal
    location /terminal {
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
    }
    
    # Root redirect to terminal
    location = / {
        return 301 /terminal;
    }
}
EOF

# Enable the site
ln -sf /etc/nginx/sites-available/web-terminal /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test nginx configuration
nginx -t

# Restart nginx
systemctl restart nginx

# Open firewall port
ufw allow 80/tcp
ufw allow 443/tcp

echo "Nginx setup complete!"
echo "Access the terminal at: http://143.110.172.229/terminal"
echo "Username: admin"
echo "Password: feet essential wherever principle"