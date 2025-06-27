#!/bin/bash

# Deploy the sessions page and set up automatic updates

set -e

echo "🔧 Deploying sessions page to VPS..."

ssh vps << 'REMOTE_SCRIPT'
set -e

# Move files into place
mv /tmp/sessions.html /var/www/terminal/
mv /tmp/generate-terminal-list.sh /root/
chmod +x /root/generate-terminal-list.sh
chown www-data:www-data /var/www/terminal/sessions.html

# Update nginx to serve the sessions page
cat >> /etc/nginx/sites-available/web-terminal << 'EOF'

    # Sessions list page
    location = /sessions {
        root /var/www/terminal;
        try_files /sessions.html =404;
    }
    
    location = /s {
        rewrite ^/s$ /sessions permanent;
    }
EOF

# Remove the duplicate closing brace if it exists
sed -i '/^}$/d' /etc/nginx/sites-available/web-terminal
echo '}' >> /etc/nginx/sites-available/web-terminal

# Test and reload nginx
nginx -t && systemctl reload nginx

# Set up a cron job to regenerate the list periodically
# This will update the list every hour
(crontab -l 2>/dev/null; echo "0 * * * * /root/generate-terminal-list.sh") | crontab -

echo "✅ Sessions page deployed!"
echo ""
echo "📱 Access your terminal sessions at:"
echo "- http://143.110.172.229/sessions"
echo "- http://143.110.172.229/s (short URL)"
echo ""
echo "The list will auto-update every hour via cron."
REMOTE_SCRIPT

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📱 MOBILE WORKFLOW:"
echo ""
echo "1. Visit http://143.110.172.229/s to see all your Code projects"
echo "2. Search for a project by typing in the search box"
echo "3. Click any project card to copy the tmux attach command"
echo "4. Go to terminal at http://143.110.172.229/"
echo "5. Paste the command with Cmd+V"
echo ""
echo "Each tmux session:"
echo "- Is named after the folder (matching your tmx function)"
echo "- Starts in the correct directory"
echo "- Persists between connections"
echo "- Can be accessed from multiple browser tabs"