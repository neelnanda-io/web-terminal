#!/bin/bash

echo "🔧 Fixing Web Terminal..."
echo ""

# 1. Stop everything
echo "1️⃣ Stopping all processes..."
pkill -f ttyd
pkill -f autossh
ssh vps 'pkill -f ttyd 2>/dev/null; systemctl stop ttyd 2>/dev/null || true'
sleep 2

# 2. Start autossh tunnel
echo "2️⃣ Starting SSH tunnel..."
autossh -M 0 -f -N \
    -R 7681:localhost:7681 \
    -o ServerAliveInterval=30 \
    -o ServerAliveCountMax=3 \
    -o ExitOnForwardFailure=yes \
    -i /Users/neelnanda/.ssh/laptop_to_vps \
    tunnel@143.110.172.229

sleep 3

# 3. Start ttyd with simple creds
echo "3️⃣ Starting ttyd..."
ttyd -p 7681 -c admin:webterm123 -W tmux > /dev/null 2>&1 &
TTYD_PID=$!
echo "Started ttyd with PID: $TTYD_PID"
sleep 2

# 4. Test everything
echo ""
echo "4️⃣ Testing..."

# Test local
if curl -s -u "admin:webterm123" http://localhost:7681/ | grep -q "ttyd"; then
    echo "✅ Local ttyd: OK"
else
    echo "❌ Local ttyd: FAILED"
fi

# Test tunnel
if ssh vps "curl -s http://localhost:7681/ | grep -q ttyd"; then
    echo "✅ SSH tunnel: OK"
else
    echo "❌ SSH tunnel: FAILED"
fi

# Test web access
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -u "admin:webterm123" http://143.110.172.229/)
if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Web access: OK"
else
    echo "❌ Web access: FAILED (HTTP $HTTP_CODE)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📝 Access Information:"
echo "URL: http://143.110.172.229/"
echo "Username: admin"
echo "Password: webterm123"
echo ""
echo "🚨 If still not working, there may be a ttyd service on the VPS interfering."
echo "   Run: ssh vps 'systemctl disable ttyd 2>/dev/null || true'"