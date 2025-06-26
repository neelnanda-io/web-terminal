#!/bin/bash

# Start ttyd with tmux session
# This script ensures a tmux session exists and starts ttyd

# Set PATH for launchd environment
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"

# Configuration
TMUX_SESSION="web-terminal"
TTYD_PORT=7681
TTYD_CREDENTIAL="admin:feet essential wherever principle"

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