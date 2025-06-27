#!/usr/bin/env python3

import os
import json
from pathlib import Path

# Get all subdirectories in ~/Code
code_dir = Path.home() / "Code"
directories = []

# Add the main Code directory
directories.append({
    "name": "Code (Top Level)",
    "path": "~/Code",
    "session": "Code"
})

# Get all subdirectories
for item in sorted(code_dir.iterdir()):
    if item.is_dir() and not item.name.startswith('.'):
        directories.append({
            "name": item.name,
            "path": f"~/Code/{item.name}",
            "session": item.name
        })

# Generate HTML
html = """<!DOCTYPE html>
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
            grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
            gap: 15px;
            margin-bottom: 30px;
        }
        
        .session-card {
            background: #1a1a1a;
            border: 1px solid #333;
            border-radius: 8px;
            padding: 15px;
            transition: all 0.2s;
            cursor: pointer;
        }
        
        .session-card:hover {
            background: #2a2a2a;
            border-color: #0af;
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(0, 170, 255, 0.2);
        }
        
        .session-name {
            font-size: 16px;
            font-weight: bold;
            color: #0af;
            margin-bottom: 5px;
        }
        
        .session-path {
            font-size: 12px;
            color: #888;
            font-family: monospace;
            margin-bottom: 10px;
        }
        
        .copy-btn {
            background: #2a2a2a;
            border: 1px solid #444;
            color: #fff;
            padding: 6px 12px;
            border-radius: 4px;
            font-size: 12px;
            cursor: pointer;
            margin-right: 5px;
        }
        
        .copy-btn:hover {
            background: #3a3a3a;
            border-color: #555;
        }
        
        .copy-btn:active {
            background: #1a1a1a;
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
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            background: rgba(0, 0, 0, 0.9);
            color: #fff;
            padding: 20px 30px;
            border-radius: 8px;
            font-size: 16px;
            z-index: 2000;
            display: none;
        }
        
        .feedback.show {
            display: block;
        }
    </style>
</head>
<body>
    <h1>Terminal Sessions</h1>
    
    <div class="info">
        <strong>How to use:</strong><br>
        • Click any card to copy the attach command<br>
        • Paste in terminal with <code>Cmd+V</code> and press Enter<br>
        • Or use <code>tmux switch -t session-name</code> if already in tmux<br>
        • Sessions are created automatically when you attach
    </div>
    
    <a href="/" class="terminal-link">← Open Terminal</a>
    
    <input type="text" class="search-box" placeholder="Search directories..." id="searchBox" autofocus>
    
    <div class="session-grid" id="sessionGrid">
"""

# Add session cards
for dir_info in directories:
    name = dir_info['name']
    path = dir_info['path']
    session = dir_info['session']
    
    html += f"""
        <div class="session-card" data-name="{name.lower()}">
            <div class="session-name">{name}</div>
            <div class="session-path">{path}</div>
            <button class="copy-btn" onclick="copyCmd('tmux new-session -As {session} -c {path}')">
                Copy Attach
            </button>
            <button class="copy-btn" onclick="copyCmd('cd {path}')">
                Copy Path
            </button>
        </div>
    """

html += """
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
        
        // Click card to copy attach command
        sessionCards.forEach(card => {
            card.addEventListener('click', (e) => {
                if (e.target.classList.contains('copy-btn')) return;
                const attachBtn = card.querySelector('.copy-btn');
                attachBtn.click();
            });
        });
        
        // Copy command function
        function copyCmd(text) {
            const btn = event.target;
            const textarea = document.getElementById('clipboard-helper');
            
            textarea.value = text;
            textarea.style.position = 'fixed';
            textarea.style.left = '0';
            textarea.style.top = '0';
            textarea.focus();
            textarea.select();
            
            try {
                document.execCommand('copy');
                showFeedback('Copied! Paste in terminal with Cmd+V');
                
                // Visual feedback on button
                const originalText = btn.textContent;
                btn.textContent = '✓ Copied';
                btn.style.background = '#2a5a2a';
                
                setTimeout(() => {
                    btn.textContent = originalText;
                    btn.style.background = '';
                }, 1000);
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
"""

# Write the HTML file
output_path = Path.home() / "Code" / "VPS" / "web-terminal" / "terminal-list.html"
with open(output_path, 'w') as f:
    f.write(html)

print(f"Generated terminal list with {len(directories)} directories")
print(f"Output: {output_path}")

# Also create a simple JSON file for potential future use
json_path = Path.home() / "Code" / "VPS" / "web-terminal" / "directories.json"
with open(json_path, 'w') as f:
    json.dump(directories, f, indent=2)