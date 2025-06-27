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
