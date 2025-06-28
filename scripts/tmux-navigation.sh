#!/bin/bash

# Script to handle tmux navigation without nesting
# This switches to existing sessions or creates new ones

SESSION_NAME="${1:-default}"
TARGET_DIR="${2:-$HOME}"

# If we're inside tmux, switch to the session
if [ -n "$TMUX" ]; then
    # Check if session exists
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        # Switch to existing session
        tmux switch-client -t "$SESSION_NAME"
    else
        # Create new session in background and switch to it
        tmux new-session -d -s "$SESSION_NAME" -c "$TARGET_DIR"
        tmux switch-client -t "$SESSION_NAME"
    fi
else
    # Not in tmux, so attach normally
    tmux new-session -As "$SESSION_NAME" -c "$TARGET_DIR"
fi