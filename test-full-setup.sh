#!/bin/bash

echo "🔍 Complete SSH Setup Test"
echo "=========================="
echo ""

# 1. Check SSH is enabled
echo "1️⃣ Checking SSH (Remote Login) status..."
if launchctl list | grep -q "com.openssh.sshd" 2>/dev/null; then
    echo "✅ SSH is enabled"
else
    # Try alternative check
    if nc -z localhost 22 2>/dev/null; then
        echo "✅ SSH is enabled (port 22 is open)"
    else
        echo "⚠️  Cannot verify SSH status (may need sudo)"
        echo "   Testing connection anyway..."
    fi
fi

echo ""
echo "2️⃣ Checking reverse tunnel..."
if ps aux | grep -q "[s]sh.*2222:localhost:22"; then
    echo "✅ Reverse tunnel is running"
else
    echo "❌ Reverse tunnel not found"
fi

echo ""
echo "3️⃣ Checking SSH agent..."
if [ -n "$SSH_AUTH_SOCK" ]; then
    echo "✅ SSH agent is active"
    echo "Keys loaded:"
    ssh-add -l | head -3
else
    echo "❌ SSH agent not running"
fi

echo ""
echo "4️⃣ Testing direct connection from VPS..."
if ssh -A vps "ssh -o ConnectTimeout=3 laptop 'echo ✅ Direct connection works!'" 2>/dev/null; then
    echo "✅ VPS → Laptop connection successful"
else
    echo "❌ Connection failed"
fi

echo ""
echo "5️⃣ Testing tmux list..."
ssh -A vps "laptop-tmux" 2>/dev/null | head -5

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📱 READY FOR YOUR OTHER DEVICES!"
echo ""
echo "Quick command for testing from another device:"
echo "  ssh -t root@143.110.172.229 laptop"
echo ""
echo "With specific tmux session:"
echo "  ssh -t root@143.110.172.229 laptop-tmux Code"
echo ""