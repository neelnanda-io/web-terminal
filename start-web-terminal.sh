#!/bin/bash

# Complete web terminal startup with logging

LOG_DIR="$HOME/Library/Logs/web-terminal"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
LOG_FILE="$LOG_DIR/startup_${TIMESTAMP}.log"

exec > >(tee -a "$LOG_FILE")
exec 2>&1

echo "=== Web Terminal Startup ==="
echo "Time: $(date)"
echo ""

# Clean up any existing processes
echo "🧹 Cleaning up old processes..."
pkill -f ttyd 2>/dev/null
pkill -f autossh 2>/dev/null
sleep 2

# Start autossh tunnel
echo ""
echo "🚇 Starting SSH tunnel..."
AUTOSSH_CMD="autossh -M 0 -N \
    -R 2222:localhost:22 \
    -R 7681:localhost:7681 \
    -R 7500:localhost:7500 \
    -R 7501:localhost:7501 \
    -R 7502:localhost:7502 \
    -o ServerAliveInterval=30 \
    -o ServerAliveCountMax=3 \
    -o ExitOnForwardFailure=yes \
    -i /Users/neelnanda/.ssh/laptop_to_vps \
    tunnel@143.110.172.229"

echo "Command: $AUTOSSH_CMD"
$AUTOSSH_CMD &
AUTOSSH_PID=$!
echo "Started autossh with PID: $AUTOSSH_PID"

# Wait for tunnel to establish
echo "Waiting for tunnel to establish..."
sleep 5

# Test tunnel
echo ""
echo "🧪 Testing tunnel..."
if ssh -o ConnectTimeout=5 vps "nc -zv localhost 7681" 2>&1 | grep -q "succeeded"; then
    echo "✅ Tunnel test successful"
else
    echo "❌ Tunnel test failed - port 7681 not accessible on VPS"
fi

# Start ttyd with simple password (no spaces, no special chars for testing)
echo ""
echo "🖥️  Starting ttyd..."
TTYD_PASSWORD="simplepass123"
TTYD_CMD="ttyd -p 7681 -c admin:${TTYD_PASSWORD} -t titleFixed='Neel Terminal' -W tmux"

echo "Command: $TTYD_CMD"
echo "Credentials: admin / ${TTYD_PASSWORD}"

$TTYD_CMD > "$LOG_DIR/ttyd_${TIMESTAMP}.log" 2>&1 &
TTYD_PID=$!
echo "Started ttyd with PID: $TTYD_PID"

# Wait for ttyd to start
sleep 3

# Test local ttyd
echo ""
echo "🧪 Testing local ttyd..."
if curl -s -u "admin:${TTYD_PASSWORD}" http://localhost:7681/ | grep -q "ttyd"; then
    echo "✅ Local ttyd test successful"
else
    echo "❌ Local ttyd test failed"
    echo "ttyd logs:"
    tail -20 "$LOG_DIR/ttyd_${TIMESTAMP}.log"
fi

# Test from VPS
echo ""
echo "🧪 Testing from VPS..."
if ssh vps "curl -s -u 'admin:${TTYD_PASSWORD}' http://localhost:7681/" | grep -q "ttyd"; then
    echo "✅ VPS ttyd test successful"
else
    echo "❌ VPS ttyd test failed"
fi

# Test through nginx
echo ""
echo "🧪 Testing through nginx..."
RESPONSE=$(curl -s -w "\n%{http_code}" -u "admin:${TTYD_PASSWORD}" http://143.110.172.229/ 2>&1)
HTTP_CODE=$(echo "$RESPONSE" | tail -1)
echo "HTTP Response Code: $HTTP_CODE"

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Nginx proxy test successful"
else
    echo "❌ Nginx proxy test failed"
    echo "Response:"
    echo "$RESPONSE" | head -20
fi

echo ""
echo "=== Summary ==="
echo "autossh PID: $AUTOSSH_PID"
echo "ttyd PID: $TTYD_PID"
echo "Logs: $LOG_FILE"
echo "ttyd logs: $LOG_DIR/ttyd_${TIMESTAMP}.log"
echo ""
echo "Access URL: http://143.110.172.229/"
echo "Username: admin"
echo "Password: ${TTYD_PASSWORD}"
echo ""

# Save current config
cat > "$LOG_DIR/current-config.txt" << EOF
Timestamp: $(date)
autossh PID: $AUTOSSH_PID
ttyd PID: $TTYD_PID
Password: ${TTYD_PASSWORD}
URL: http://143.110.172.229/
SSH: ssh -t root@143.110.172.229 laptop
EOF

echo "Configuration saved to: $LOG_DIR/current-config.txt"