#!/bin/bash

# Start ttyd with tmux session
# This script ensures a tmux session exists and starts ttyd

# Set PATH for launchd environment
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"

# Load credentials from external file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/credentials.sh" ]; then
    source "$SCRIPT_DIR/credentials.sh"
else
    echo "ERROR: credentials.sh not found! Copy credentials.example.sh to credentials.sh and update it."
    exit 1
fi

# Configuration
TMUX_SESSION="web-terminal"
TTYD_PORT="${TTYD_PORT:-7681}"
TTYD_CREDENTIAL="${TTYD_USERNAME}:${TTYD_PASSWORD}"

# Ensure tmux session exists
if ! tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
    echo "Creating new tmux session: $TMUX_SESSION"
    tmux new-session -d -s "$TMUX_SESSION"
fi

# Start ttyd with authentication
echo "Starting ttyd on port $TTYD_PORT..."
echo "Access will require username: admin"

# Start ttyd
# -p: port
# -c: credentials (username:password)
# -t: terminal title
# -W: writable (allow input)
exec ttyd \
    -p "$TTYD_PORT" \
    -c "$TTYD_CREDENTIAL" \
    -t "titleFixed=Neel's Terminal" \
    -W \
    tmux attach-session -t "$TMUX_SESSION"