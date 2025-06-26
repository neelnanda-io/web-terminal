// Terminal setup
const term = new Terminal({
    cursorBlink: true,
    fontSize: 14,
    fontFamily: 'Menlo, Monaco, "Courier New", monospace',
    theme: {
        background: '#000000',
        foreground: '#ffffff',
        cursor: '#ffffff',
        selection: '#4d4d4d'
    },
    scrollback: 10000,
    convertEol: true
});

// Add-ons
const fitAddon = new FitAddon.FitAddon();
const webLinksAddon = new WebLinksAddon.WebLinksAddon();
term.loadAddon(fitAddon);
term.loadAddon(webLinksAddon);

// WebSocket connection
let socket = null;
let reconnectTimer = null;
let currentWindow = 0;
let isReconnecting = false;

// Get server URL from environment
const getServerUrl = () => {
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const host = window.location.hostname;
    const port = window.location.port || (protocol === 'wss:' ? '443' : '80');
    return `${protocol}//${host}:${port}/ws`;
};

// Terminal initialization
function initTerminal() {
    term.open(document.getElementById('terminal'));
    fitAddon.fit();
    
    // Handle window resize
    window.addEventListener('resize', () => {
        fitAddon.fit();
        if (socket && socket.readyState === WebSocket.OPEN) {
            const dims = { cols: term.cols, rows: term.rows };
            socket.send(JSON.stringify({ type: 'resize', ...dims }));
        }
    });
    
    // Handle terminal input
    term.onData(data => {
        if (socket && socket.readyState === WebSocket.OPEN) {
            socket.send(JSON.stringify({ type: 'input', data: data }));
        }
    });
}

// WebSocket connection management
function connect() {
    updateStatus('Connecting...');
    
    socket = new WebSocket(getServerUrl());
    
    socket.onopen = () => {
        console.log('WebSocket connected');
        updateStatus('Connected');
        isReconnecting = false;
        
        // Send initial resize
        const dims = { cols: term.cols, rows: term.rows };
        socket.send(JSON.stringify({ type: 'resize', ...dims }));
        
        // Navigate to window if specified in URL
        handleUrlNavigation();
        
        // Update tmux windows list
        updateTmuxWindows();
    };
    
    socket.onmessage = (event) => {
        const data = JSON.parse(event.data);
        
        switch (data.type) {
            case 'output':
                term.write(data.data);
                break;
            case 'exit':
                updateStatus('Session ended');
                handleReconnect();
                break;
            case 'error':
                console.error('Server error:', data.message);
                updateStatus(`Error: ${data.message}`);
                break;
        }
    };
    
    socket.onerror = (error) => {
        console.error('WebSocket error:', error);
        updateStatus('Connection error');
    };
    
    socket.onclose = () => {
        updateStatus('Disconnected');
        handleReconnect();
    };
}

// Reconnection logic
function handleReconnect() {
    if (!isReconnecting) {
        isReconnecting = true;
        reconnectTimer = setTimeout(() => {
            console.log('Attempting to reconnect...');
            connect();
        }, 3000);
    }
}

// Control panel functionality
function sendCommand(command) {
    if (socket && socket.readyState === WebSocket.OPEN) {
        socket.send(JSON.stringify({ type: 'input', data: command + '\n' }));
    }
}

function sendKey(key) {
    if (socket && socket.readyState === WebSocket.OPEN) {
        let data = '';
        
        switch (key) {
            case 'ArrowUp':
                data = '\x1b[A';
                break;
            case 'ArrowDown':
                data = '\x1b[B';
                break;
            case 'ArrowLeft':
                data = '\x1b[D';
                break;
            case 'ArrowRight':
                data = '\x1b[C';
                break;
            case 'Home':
                data = '\x1b[H';
                break;
            case 'End':
                data = '\x1b[F';
                break;
            case 'Tab':
                data = '\t';
                break;
            case 'Escape':
                data = '\x1b';
                break;
            case 'Enter':
                data = '\r';
                break;
            case 'Backspace':
                data = '\x7f';
                break;
            default:
                data = key;
        }
        
        socket.send(JSON.stringify({ type: 'input', data: data }));
    }
}

function sendCtrlKey(key, followUp) {
    if (socket && socket.readyState === WebSocket.OPEN) {
        // Send Ctrl+key
        const code = key.charCodeAt(0) - 96; // Convert to control character
        socket.send(JSON.stringify({ type: 'input', data: String.fromCharCode(code) }));
        
        // If there's a follow-up key (for tmux commands)
        if (followUp) {
            setTimeout(() => {
                socket.send(JSON.stringify({ type: 'input', data: followUp }));
            }, 50);
        }
    }
}

// Tmux window management
function updateTmuxWindows() {
    // Send command to list tmux windows
    sendCommand('tmux list-windows -F "#{window_index}:#{window_name}"');
    
    // Parse the output (this is simplified - in production you'd parse the actual output)
    setTimeout(() => {
        // For now, just update based on URL or default
        const windowsContainer = document.getElementById('tmux-windows');
        windowsContainer.innerHTML = '';
        
        // Check for windows based on common folder names
        const commonFolders = ['Code', 'Documents', 'Projects', 'web-terminal'];
        commonFolders.forEach((folder, index) => {
            const btn = document.createElement('button');
            btn.className = 'window-btn';
            btn.dataset.window = index;
            btn.textContent = `${index}: ${folder}`;
            btn.onclick = () => navigateToWindow(index);
            if (index === currentWindow) {
                btn.classList.add('active');
            }
            windowsContainer.appendChild(btn);
        });
    }, 500);
}

function navigateToWindow(windowIndex) {
    currentWindow = windowIndex;
    sendCtrlKey('b', windowIndex.toString());
    
    // Update UI
    document.querySelectorAll('.window-btn').forEach(btn => {
        btn.classList.toggle('active', parseInt(btn.dataset.window) === windowIndex);
    });
    
    document.getElementById('window-info').textContent = `Window: ${windowIndex}`;
}

// URL-based navigation
function handleUrlNavigation() {
    const path = window.location.pathname;
    const match = path.match(/\/(\w+)$/);
    
    if (match) {
        const folderName = match[1];
        // Try to find and navigate to the window
        // This would be more sophisticated in production
        const windowIndex = getWindowIndexByName(folderName);
        if (windowIndex !== -1) {
            navigateToWindow(windowIndex);
        }
    }
}

function getWindowIndexByName(name) {
    // Simplified - in production, you'd actually parse tmux window list
    const commonFolders = ['Code', 'Documents', 'Projects', 'web-terminal'];
    return commonFolders.findIndex(folder => 
        folder.toLowerCase() === name.toLowerCase()
    );
}

// UI helpers
function updateStatus(status) {
    document.getElementById('connection-status').textContent = status;
}

// Panel toggle
document.getElementById('toggle-panel').addEventListener('click', () => {
    const panel = document.getElementById('control-panel');
    const container = document.getElementById('terminal-container');
    const toggleBtn = document.getElementById('toggle-panel');
    
    panel.classList.toggle('collapsed');
    container.classList.toggle('shifted');
    toggleBtn.classList.toggle('shifted');
    
    // Refit terminal after animation
    setTimeout(() => {
        fitAddon.fit();
    }, 300);
});

// Keyboard event handling for better cross-platform support
document.addEventListener('keydown', (e) => {
    // Handle Command key on macOS as Ctrl
    if (e.metaKey || e.ctrlKey) {
        // Prevent default browser shortcuts
        if (['a', 'c', 'v', 'x', 'z'].includes(e.key.toLowerCase())) {
            e.preventDefault();
            
            // Convert to terminal control sequences
            if (e.key === 'c') {
                sendCtrlKey('c');
            } else if (e.key === 'v' && navigator.clipboard) {
                // Handle paste
                navigator.clipboard.readText().then(text => {
                    if (socket && socket.readyState === WebSocket.OPEN) {
                        socket.send(JSON.stringify({ type: 'input', data: text }));
                    }
                });
            }
        }
    }
    
    // Fix for Command+Arrow on macOS
    if (e.metaKey && (e.key.includes('Arrow') || e.key === 'Backspace')) {
        e.preventDefault();
        
        if (e.key === 'ArrowLeft') {
            sendKey('Home');
        } else if (e.key === 'ArrowRight') {
            sendKey('End');
        } else if (e.key === 'Backspace') {
            // Delete to beginning of line
            sendCtrlKey('u');
        }
    }
});

// Mobile touch handling for better experience
let touchStartX = 0;
let touchStartY = 0;

document.getElementById('terminal').addEventListener('touchstart', (e) => {
    touchStartX = e.touches[0].clientX;
    touchStartY = e.touches[0].clientY;
});

document.getElementById('terminal').addEventListener('touchend', (e) => {
    const touchEndX = e.changedTouches[0].clientX;
    const touchEndY = e.changedTouches[0].clientY;
    
    const deltaX = touchEndX - touchStartX;
    const deltaY = touchEndY - touchStartY;
    
    // Swipe right to show panel
    if (deltaX > 50 && Math.abs(deltaY) < 30) {
        const panel = document.getElementById('control-panel');
        const container = document.getElementById('terminal-container');
        const toggleBtn = document.getElementById('toggle-panel');
        
        panel.classList.remove('collapsed');
        container.classList.add('shifted');
        toggleBtn.classList.add('shifted');
        
        setTimeout(() => fitAddon.fit(), 300);
    }
});

// Initialize everything
initTerminal();
connect();

// Auto-hide panel on mobile after action
if (window.innerWidth <= 768) {
    document.querySelectorAll('.control-btn, .window-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            setTimeout(() => {
                const panel = document.getElementById('control-panel');
                const container = document.getElementById('terminal-container');
                const toggleBtn = document.getElementById('toggle-panel');
                
                panel.classList.add('collapsed');
                container.classList.remove('shifted');
                toggleBtn.classList.remove('shifted');
                
                setTimeout(() => fitAddon.fit(), 300);
            }, 300);
        });
    });
}