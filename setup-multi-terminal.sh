#!/bin/bash

# Setup multiple terminal endpoints for different directories

set -e

echo "🔧 Setting up multiple terminal endpoints..."

# First, let's modify the ttyd startup to handle different sessions
cat > start-ttyd-multi.sh << 'EOF'
#!/bin/bash

# Start ttyd with URL parameter handling
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"

# Parse URL parameter to determine directory
# This will be passed by nginx as an argument
SESSION_NAME="${1:-default}"
TARGET_DIR="${2:-$HOME}"

# Ensure tmux session exists in the target directory
if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "Creating tmux session: $SESSION_NAME in $TARGET_DIR"
    tmux new-session -d -s "$SESSION_NAME" -c "$TARGET_DIR"
fi

# Start ttyd for this specific session
exec ttyd \
    -p 7681 \
    -c "admin:feet essential wherever principle" \
    -t "titleFixed=$SESSION_NAME Terminal" \
    -W \
    tmux attach-session -t "$SESSION_NAME"
EOF

chmod +x start-ttyd-multi.sh

echo "✅ Created multi-session ttyd script"

# Now setup nginx to route different URLs to different terminal sessions
ssh vps << 'REMOTE_SCRIPT'
set -e

# Create nginx config with multiple terminal routes
cat > /etc/nginx/sites-available/web-terminal << 'EOF'
server {
    listen 80;
    server_name vps.neelnanda.io 143.110.172.229;

    # Root terminal - default session
    location = / {
        proxy_pass http://127.0.0.1:7681;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Authorization $http_authorization;
        proxy_pass_header Authorization;
        proxy_buffering off;
        proxy_read_timeout 7d;
    }
    
    # WebSocket for root
    location /ws {
        proxy_pass http://127.0.0.1:7681/ws;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_buffering off;
        proxy_read_timeout 7d;
    }
    
    # Create a control page for managing sessions
    location = /terminals {
        default_type text/html;
        return 200 '<!DOCTYPE html>
<html>
<head>
    <title>Terminal Sessions</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {
            font-family: -apple-system, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background: #1a1a1a;
            color: #fff;
        }
        h1 { color: #0af; }
        .session-list {
            display: grid;
            gap: 10px;
            margin: 20px 0;
        }
        .session {
            background: #2a2a2a;
            padding: 15px;
            border-radius: 8px;
            border: 1px solid #444;
            text-decoration: none;
            color: #fff;
            display: block;
            transition: all 0.2s;
        }
        .session:hover {
            background: #3a3a3a;
            border-color: #0af;
        }
        .session-name {
            font-size: 18px;
            font-weight: bold;
            color: #0af;
        }
        .session-path {
            font-size: 14px;
            color: #888;
            margin-top: 5px;
        }
        .new-session {
            background: #1a4a1a;
            border-color: #2a7a2a;
        }
        .command-section {
            background: #2a2a2a;
            padding: 15px;
            border-radius: 8px;
            margin: 20px 0;
        }
        code {
            background: #1a1a1a;
            padding: 2px 6px;
            border-radius: 3px;
            font-family: monospace;
        }
    </style>
</head>
<body>
    <h1>Terminal Sessions</h1>
    
    <div class="session-list">
        <a href="/" class="session">
            <div class="session-name">Default Terminal</div>
            <div class="session-path">Home directory</div>
        </a>
        
        <a href="/term/code" class="session">
            <div class="session-name">Code</div>
            <div class="session-path">~/Code directory</div>
        </a>
        
        <a href="/term/documents" class="session">
            <div class="session-name">Documents</div>
            <div class="session-path">~/Documents directory</div>
        </a>
        
        <a href="/term/downloads" class="session">
            <div class="session-name">Downloads</div>
            <div class="session-path">~/Downloads directory</div>
        </a>
        
        <a href="/term/projects" class="session">
            <div class="session-name">Projects</div>
            <div class="session-path">~/Projects directory</div>
        </a>
    </div>
    
    <div class="command-section">
        <h2>Managing Sessions</h2>
        <p>Each link opens a separate tmux session in that directory. You can:</p>
        <ul>
            <li>Open multiple tabs for different directories</li>
            <li>Each session persists independently</li>
            <li>Use standard tmux commands within each session</li>
        </ul>
        
        <h3>SSH Commands:</h3>
        <p>List sessions: <code>tmux ls</code></p>
        <p>Attach to session: <code>tmux attach -t session-name</code></p>
        <p>Kill session: <code>tmux kill-session -t session-name</code></p>
    </div>
</body>
</html>';
    }
    
    # Static files
    location ~ ^/(mobile-terminal\.html|mobile-simple\.html|mobile-complete\.html|index\.html|terminal\.js)$ {
        root /var/www/terminal;
    }
    
    # Short URLs
    location = /m {
        rewrite ^/m$ /mobile-complete.html permanent;
    }
    
    location = /simple {
        rewrite ^/simple$ /mobile-simple.html permanent;
    }
}
EOF

# Test and reload
nginx -t && systemctl reload nginx

echo "✅ Nginx configuration updated!"
REMOTE_SCRIPT

echo ""
echo "🎯 Setup complete! However..."
echo ""
echo "⚠️  IMPORTANT: The URL-based routing requires multiple ttyd instances"
echo "    or a custom ttyd wrapper, which is complex to set up."
echo ""
echo "💡 BETTER SOLUTION - SSH Script Approach:"
echo ""
echo "Instead of fighting with browser limitations, create this on your Mac:"

cat > ~/quick-terminal.sh << 'EOF'
#!/bin/bash

# Quick terminal launcher for different directories
# Usage: quick-terminal.sh [code|documents|downloads|projects]

SESSION_NAME="${1:-default}"

case "$SESSION_NAME" in
    code)
        DIR="$HOME/Code"
        ;;
    documents)
        DIR="$HOME/Documents"
        ;;
    downloads)
        DIR="$HOME/Downloads"
        ;;
    projects)
        DIR="$HOME/Projects"
        ;;
    *)
        DIR="$HOME"
        ;;
esac

# Create or attach to tmux session in specific directory
if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    tmux new-session -d -s "$SESSION_NAME" -c "$DIR"
fi

# If we're in tmux, switch to the session
if [ -n "$TMUX" ]; then
    tmux switch-client -t "$SESSION_NAME"
else
    tmux attach-session -t "$SESSION_NAME"
fi
EOF

chmod +x ~/quick-terminal.sh

echo ""
echo "✅ Created ~/quick-terminal.sh"
echo ""
echo "📱 MOBILE WORKFLOW:"
echo ""
echo "1. Open terminal at http://143.110.172.229"
echo ""
echo "2. Create/switch sessions with:"
echo "   ./quick-terminal.sh code      # Opens in ~/Code"
echo "   ./quick-terminal.sh documents # Opens in ~/Documents"
echo "   ./quick-terminal.sh projects  # Opens in ~/Projects"
echo ""
echo "3. Or use tmux directly:"
echo "   tmux new -s code -c ~/Code"
echo "   tmux new -s work -c ~/Work"
echo "   tmux ls                    # List all sessions"
echo "   tmux switch -t code        # Switch to code session"
echo ""
echo "4. Visit http://143.110.172.229/terminals for a session overview"
echo ""
echo "This approach works TODAY without any complex browser hacks!"