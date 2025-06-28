#!/bin/bash

# Start ttyd with a password that works with browser auth
# Using hyphens instead of spaces for compatibility

MAIN_SESSION="${1:-}"

# Simple password without spaces
PASSWORD="feet-essential-wherever-principle"

if [ -z "$MAIN_SESSION" ]; then
    echo "Starting ttyd without specific session..."
    ttyd -p 7681 -c "admin:$PASSWORD" -t titleFixed="Neel's Terminal" -W tmux
else
    echo "Starting ttyd attached to session: $MAIN_SESSION"
    ttyd -p 7681 -c "admin:$PASSWORD" -t titleFixed="Neel's Terminal" -W tmux attach-session -t "$MAIN_SESSION"
fi