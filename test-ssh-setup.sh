#!/bin/bash

# Test SSH setup without sudo

echo "🔍 Checking SSH Setup Status..."
echo ""

# Check if SSH daemon is running
if launchctl list | grep -q "com.openssh.sshd"; then
    echo "✅ SSH daemon is running"
    SSH_ENABLED=true
else
    echo "❌ SSH daemon is NOT running"
    echo ""
    echo "To enable SSH on your Mac:"
    echo "1. Open System Settings"
    echo "2. Go to General → Sharing"
    echo "3. Turn ON 'Remote Login' (allow access for your user)"
    echo ""
    echo "After enabling, run this script again to test the connection."
    SSH_ENABLED=false
fi

echo ""

# Check reverse tunnel
if ps aux | grep -q "[s]sh.*2222:localhost:22"; then
    echo "✅ Reverse tunnel (port 2222) is running"
else
    echo "❌ Reverse tunnel not found"
    echo "The autossh service should include: -R 2222:localhost:22"
fi

echo ""

# If SSH is enabled, test the connections
if [ "$SSH_ENABLED" = true ]; then
    echo "🧪 Testing local SSH..."
    if timeout 3 ssh -o StrictHostKeyChecking=no localhost "echo 'Local SSH works!'" 2>/dev/null; then
        echo "✅ Local SSH connection successful"
        
        echo ""
        echo "🧪 Testing connection from VPS..."
        if ssh vps "timeout 5 ssh -o StrictHostKeyChecking=no laptop 'echo Connected to MacBook!'" 2>/dev/null; then
            echo "✅ VPS → MacBook connection works!"
            
            echo ""
            echo "🎉 Everything is working! You can now:"
            echo ""
            echo "From your Android phone or other Mac:"
            echo "  ssh -t root@143.110.172.229 laptop"
            echo "  ssh -t root@143.110.172.229 laptop-tmux Code"
            echo ""
        else
            echo "❌ VPS connection failed"
            echo "Check if the VPS has the correct SSH key and config"
        fi
    else
        echo "❌ Local SSH test failed"
        echo "SSH might be enabled but not accepting connections"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Current Status Summary:"
echo ""
ps aux | grep -E "[s]sh.*2222|[a]utossh" | while read line; do
    echo "Process: $(echo $line | awk '{print $11, $12, $13, $14}')"
done