#!/bin/bash

# Simpler session list generator

OUTPUT_FILE="sessions.html"

# Start HTML
cat > "$OUTPUT_FILE" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Terminal Sessions</title>
    <style>
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #0a0a0a;
            color: #fff;
            padding: 20px;
            max-width: 1200px;
            margin: 0 auto;
        }
        
        h1 {
            color: #0af;
            margin-bottom: 10px;
        }
        
        .info {
            background: #1a1a1a;
            border: 1px solid #333;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
            font-size: 14px;
            line-height: 1.6;
        }
        
        .info code {
            background: #2a2a2a;
            padding: 2px 6px;
            border-radius: 3px;
            font-family: monospace;
        }
        
        .session-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
            gap: 12px;
            margin-bottom: 30px;
        }
        
        .session-card {
            background: #1a1a1a;
            border: 1px solid #333;
            border-radius: 8px;
            padding: 12px;
            transition: all 0.2s;
            cursor: pointer;
            position: relative;
        }
        
        .session-card:hover {
            background: #2a2a2a;
            border-color: #0af;
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(0, 170, 255, 0.2);
        }
        
        .session-name {
            font-size: 15px;
            font-weight: bold;
            color: #0af;
            margin-bottom: 5px;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }
        
        .session-path {
            font-size: 11px;
            color: #888;
            font-family: monospace;
            margin-bottom: 8px;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }
        
        .copy-btn {
            background: #2a2a2a;
            border: 1px solid #444;
            color: #fff;
            padding: 5px 10px;
            border-radius: 4px;
            font-size: 11px;
            cursor: pointer;
            margin-right: 5px;
        }
        
        .copy-btn:hover {
            background: #3a3a3a;
            border-color: #555;
        }
        
        .terminal-link {
            display: inline-block;
            background: #0a4a8a;
            color: #fff;
            padding: 10px 20px;
            border-radius: 6px;
            text-decoration: none;
            margin: 10px 0;
        }
        
        .search-box {
            width: 100%;
            padding: 12px;
            background: #1a1a1a;
            border: 1px solid #333;
            color: #fff;
            border-radius: 6px;
            font-size: 16px;
            margin-bottom: 20px;
        }
        
        .search-box:focus {
            outline: none;
            border-color: #0af;
        }
        
        #clipboard-helper {
            position: absolute;
            left: -9999px;
        }
        
        .feedback {
            position: fixed;
            bottom: 20px;
            right: 20px;
            background: rgba(0, 0, 0, 0.9);
            color: #fff;
            padding: 15px 20px;
            border-radius: 8px;
            font-size: 14px;
            z-index: 2000;
            display: none;
            border: 1px solid #0af;
        }
        
        .feedback.show {
            display: block;
        }
        
        .command-section {
            background: #1a1a1a;
            border: 1px solid #333;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
        }
        
        .command-section h3 {
            color: #0af;
            margin-bottom: 10px;
            font-size: 16px;
        }
        
        .command-list {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 10px;
        }
        
        .cmd {
            background: #2a2a2a;
            padding: 8px 12px;
            border-radius: 4px;
            font-family: monospace;
            font-size: 12px;
            cursor: pointer;
            transition: all 0.2s;
        }
        
        .cmd:hover {
            background: #3a3a3a;
            border: 1px solid #0af;
        }
    </style>
</head>
<body>
    <h1>Terminal Sessions</h1>
    
    <div class="info">
        <strong>You're already in tmux!</strong> Use these commands:<br>
        • <code>Ctrl+B, S</code> - Show session list (arrow keys to select)<br>
        • <code>Ctrl+B, (</code> - Previous session<br>
        • <code>Ctrl+B, )</code> - Next session<br>
        • Or copy the switch commands below
    </div>
    
    <div class="command-section">
        <h3>Quick Switch Commands</h3>
        <div class="command-list">
            <div class="cmd" onclick="copyCmd('tmux switch -t Code')">Switch to Code</div>
            <div class="cmd" onclick="copyCmd('tmux switch -t ClaudePhone')">Switch to ClaudePhone</div>
            <div class="cmd" onclick="copyCmd('tmux switch -t VPS')">Switch to VPS</div>
            <div class="cmd" onclick="copyCmd('tmux ls')">List all sessions</div>
        </div>
    </div>
    
    <a href="/" class="terminal-link">← Back to Terminal</a>
    
    <input type="text" class="search-box" placeholder="Search projects..." id="searchBox" autofocus>
    
    <div class="session-grid" id="sessionGrid">
EOF

# Add Code (top level) first
cat >> "$OUTPUT_FILE" << EOF
        <div class="session-card" data-name="code (top level)">
            <div class="session-name" title="Code (Top Level)">Code (Top Level)</div>
            <div class="session-path" title="~/Code">~/Code</div>
            <button class="copy-btn" onclick="copyCmd('tmux switch -t Code || tmux new -d -s Code -c ~/Code')">Switch</button>
            <button class="copy-btn" onclick="copyCmd('cd ~/Code')">cd</button>
        </div>
EOF

# Add all subdirectories
for dir in ~/Code/*/; do
    if [ -d "$dir" ]; then
        dirname=$(basename "$dir")
        # Skip hidden directories
        if [[ ! "$dirname" =~ ^\. ]]; then
            cat >> "$OUTPUT_FILE" << EOF
        <div class="session-card" data-name="$(echo "$dirname" | tr '[:upper:]' '[:lower:]')">
            <div class="session-name" title="$dirname">$dirname</div>
            <div class="session-path" title="~/Code/$dirname">~/Code/$dirname</div>
            <button class="copy-btn" onclick="copyCmd('tmux switch -t $dirname || tmux new -d -s $dirname -c ~/Code/$dirname')">Switch</button>
            <button class="copy-btn" onclick="copyCmd('cd ~/Code/$dirname')">cd</button>
        </div>
EOF
        fi
    fi
done

# Close HTML
cat >> "$OUTPUT_FILE" << 'EOF'
    </div>
    
    <textarea id="clipboard-helper"></textarea>
    <div id="feedback" class="feedback"></div>
    
    <script>
        // Search functionality
        const searchBox = document.getElementById('searchBox');
        const sessionCards = document.querySelectorAll('.session-card');
        
        searchBox.addEventListener('input', (e) => {
            const searchTerm = e.target.value.toLowerCase();
            
            sessionCards.forEach(card => {
                const name = card.dataset.name;
                if (name.includes(searchTerm)) {
                    card.style.display = 'block';
                } else {
                    card.style.display = 'none';
                }
            });
        });
        
        // Click card to copy switch command
        sessionCards.forEach(card => {
            card.addEventListener('click', (e) => {
                if (e.target.classList.contains('copy-btn')) return;
                const switchBtn = card.querySelector('.copy-btn');
                switchBtn.click();
            });
        });
        
        // Copy command function
        function copyCmd(text) {
            const btn = event.target || event.currentTarget;
            const textarea = document.getElementById('clipboard-helper');
            
            textarea.value = text;
            textarea.style.position = 'fixed';
            textarea.style.left = '0';
            textarea.style.top = '0';
            textarea.focus();
            textarea.select();
            
            try {
                document.execCommand('copy');
                showFeedback('✓ Copied! Paste with Cmd+V');
                
                // Visual feedback
                if (btn.classList.contains('copy-btn')) {
                    const originalText = btn.textContent;
                    btn.textContent = '✓';
                    btn.style.background = '#2a5a2a';
                    
                    setTimeout(() => {
                        btn.textContent = originalText;
                        btn.style.background = '';
                    }, 1000);
                }
            } catch (err) {
                console.error('Copy failed:', err);
                showFeedback('Copy failed - select manually');
            }
            
            textarea.style.position = 'absolute';
            textarea.style.left = '-9999px';
        }
        
        // Show feedback
        function showFeedback(message) {
            const feedback = document.getElementById('feedback');
            feedback.textContent = message;
            feedback.classList.add('show');
            
            setTimeout(() => {
                feedback.classList.remove('show');
            }, 2000);
        }
    </script>
</body>
</html>
EOF

echo "Generated sessions.html with $(find ~/Code -maxdepth 1 -type d | wc -l) directories"