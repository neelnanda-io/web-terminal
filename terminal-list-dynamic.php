<?php
// Dynamic terminal list generator
// This PHP script generates the list on each request

$code_dir = $_SERVER['HOME'] . '/Code';
$directories = [];

// Add the main Code directory
$directories[] = [
    'name' => 'Code (Top Level)',
    'path' => '~/Code',
    'session' => 'Code'
];

// Get all subdirectories
if (is_dir($code_dir)) {
    $items = scandir($code_dir);
    foreach ($items as $item) {
        if ($item != '.' && $item != '..' && is_dir($code_dir . '/' . $item) && $item[0] != '.') {
            $directories[] = [
                'name' => $item,
                'path' => '~/Code/' . $item,
                'session' => $item
            ];
        }
    }
}

// Sort by name
usort($directories, function($a, $b) {
    return strcasecmp($a['name'], $b['name']);
});

?><!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Terminal Sessions - <?php echo count($directories); ?> Projects</title>
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
        
        .stats {
            color: #888;
            font-size: 14px;
            margin-bottom: 20px;
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
        
        @media (max-width: 768px) {
            .session-grid {
                grid-template-columns: 1fr;
            }
            
            body {
                padding: 10px;
            }
        }
    </style>
</head>
<body>
    <h1>Terminal Sessions</h1>
    <div class="stats">
        <?php echo count($directories); ?> projects • Updated: <?php echo date('Y-m-d H:i:s'); ?>
    </div>
    
    <div class="info">
        <strong>Quick tips:</strong><br>
        • Click card or "Attach" to copy tmux command<br>
        • Sessions persist across connections<br>
        • Use <code>tmux ls</code> to see active sessions<br>
        • Mobile: Tap to copy, then paste in terminal
    </div>
    
    <a href="/" class="terminal-link">← Open Terminal</a>
    
    <input type="text" class="search-box" placeholder="Search <?php echo count($directories); ?> projects..." id="searchBox" autofocus>
    
    <div class="session-grid" id="sessionGrid">
        <?php foreach ($directories as $dir): ?>
        <div class="session-card" data-name="<?php echo strtolower($dir['name']); ?>">
            <div class="session-name" title="<?php echo htmlspecialchars($dir['name']); ?>">
                <?php echo htmlspecialchars($dir['name']); ?>
            </div>
            <div class="session-path" title="<?php echo htmlspecialchars($dir['path']); ?>">
                <?php echo htmlspecialchars($dir['path']); ?>
            </div>
            <button class="copy-btn" onclick="copyCmd('tmux new-session -As <?php echo $dir['session']; ?> -c <?php echo $dir['path']; ?>')">
                Attach
            </button>
            <button class="copy-btn" onclick="copyCmd('cd <?php echo $dir['path']; ?>')">
                cd
            </button>
        </div>
        <?php endforeach; ?>
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
                showFeedback('✓ Copied! Paste with Cmd+V');
                
                // Visual feedback on button
                const originalText = btn.textContent;
                btn.textContent = '✓';
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
        
        // Keyboard shortcut - Enter to go to terminal
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Enter' && e.target.tagName !== 'INPUT') {
                window.location.href = '/';
            }
        });
    </script>
</body>
</html>