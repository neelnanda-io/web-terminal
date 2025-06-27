#!/bin/bash

# Quick test of the new secure setup

echo "🔒 Testing Secure SSH Setup"
echo ""

# Check if SSH agent is running
if [ -z "$SSH_AUTH_SOCK" ]; then
    echo "⚠️  SSH Agent not running. Starting it..."
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/vps 2>/dev/null
else
    echo "✅ SSH Agent is running"
fi

echo ""
echo "🔑 Keys in SSH Agent:"
ssh-add -l | head -3

echo ""
echo "🧪 Testing connection with agent forwarding..."
echo "(This will fail if SSH is not enabled on your Mac)"
echo ""

if ssh -A vps "ssh -o ConnectTimeout=3 laptop 'echo ✅ SUCCESS: Connected via agent forwarding!'" 2>&1 | grep -q "SUCCESS"; then
    echo ""
    echo "🎉 Everything works! You can now connect from any device with:"
    echo "   ssh -A -t root@143.110.172.229 laptop"
    echo ""
else
    echo "❌ Connection failed. Please:"
    echo "1. Enable SSH on your Mac (System Settings → General → Sharing → Remote Login)"
    echo "2. Run this test again"
fi