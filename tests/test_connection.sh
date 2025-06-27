#!/bin/bash
# Test script for verifying web terminal connection

set -e

echo "Web Terminal Connection Test"
echo "==========================="
echo

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Check for credentials
if [ ! -f "$PROJECT_ROOT/credentials.sh" ]; then
    echo "❌ ERROR: credentials.sh not found!"
    echo "   Copy credentials.example.sh to credentials.sh and configure it."
    exit 1
fi

source "$PROJECT_ROOT/credentials.sh"

# Test 1: Check if ttyd is running
echo "1. Checking ttyd process..."
if pgrep -f ttyd > /dev/null; then
    echo "   ✓ ttyd is running"
else
    echo "   ✗ ttyd is not running"
    echo "   Start it with: $PROJECT_ROOT/start-ttyd.sh"
fi

# Test 2: Check local ttyd connection
echo
echo "2. Testing local ttyd connection..."
if curl -s -f -u "$TTYD_USERNAME:$TTYD_PASSWORD" http://localhost:${TTYD_PORT:-7681}/ > /dev/null; then
    echo "   ✓ Local ttyd connection successful"
else
    echo "   ✗ Local ttyd connection failed"
fi

# Test 3: Check SSH tunnel (if VPS details provided)
if [ -n "$VPS_HOST" ]; then
    echo
    echo "3. Checking SSH tunnel to VPS..."
    if ssh -o ConnectTimeout=5 -p ${VPS_PORT:-22} ${VPS_USER}@${VPS_HOST} "exit" 2>/dev/null; then
        echo "   ✓ SSH connection to VPS successful"
    else
        echo "   ✗ SSH connection to VPS failed"
    fi
fi

# Test 4: Check tmux session
echo
echo "4. Checking tmux session..."
if tmux has-session -t web-terminal 2>/dev/null; then
    echo "   ✓ tmux session 'web-terminal' exists"
    WINDOWS=$(tmux list-windows -t web-terminal -F '#W' | tr '\n' ', ' | sed 's/,$//')
    echo "   Windows: $WINDOWS"
else
    echo "   ✗ tmux session 'web-terminal' not found"
fi

echo
echo "Test complete!"