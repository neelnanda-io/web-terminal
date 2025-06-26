# Project Memory

## Purpose
This project provides web-based access to a tmux session running on the user's laptop through their VPS. It allows accessing the laptop's terminal from any device with a web browser by visiting a URL on the VPS, enabling remote command execution and interactive terminal sessions.

## Key Technologies
- ttyd - Terminal emulator for the web
- tmux - Terminal multiplexer for persistent sessions
- nginx - Reverse proxy on VPS for web access
- autossh - Maintains reverse SSH tunnel
- Basic HTTP authentication for security

## Architecture Overview
1. **Laptop** runs ttyd connected to a tmux session on port 7681
2. **Reverse SSH tunnel** forwards port 7681 from laptop to VPS
3. **VPS nginx** proxies web requests to the tunneled ttyd port
4. **Web browser** connects to VPS URL and gets interactive terminal

## Development Notes
- ttyd must be started with tmux attach command
- WebSocket support required in nginx for terminal interaction
- Port 7681 is standard for ttyd but configurable
- Authentication prevents public access to terminal
- Tmux session persists even if ttyd restarts