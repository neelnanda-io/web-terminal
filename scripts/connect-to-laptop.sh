#!/bin/bash

# Simple script to connect to laptop via VPS
# Usage: ./connect-to-laptop.sh [session-name]

VPS_HOST="143.110.172.229"
VPS_USER="root"
SESSION="$1"

if [ -z "$SESSION" ]; then
    echo "Connecting to laptop..."
    ssh -t $VPS_USER@$VPS_HOST "laptop"
else
    echo "Connecting to tmux session: $SESSION"
    ssh -t $VPS_USER@$VPS_HOST "laptop-tmux '$SESSION'"
fi
