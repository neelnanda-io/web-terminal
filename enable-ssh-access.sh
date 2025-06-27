#!/bin/bash

# Enable SSH access on macOS and complete setup

echo "🔧 Setting up SSH access on your Mac..."
echo ""

# Check if SSH is enabled
if ! sudo launchctl list | grep -q "com.openssh.sshd"; then
    echo "📱 SSH (Remote Login) is not enabled on your Mac."
    echo ""
    echo "To enable it:"
    echo "1. Open System Settings"
    echo "2. Go to General → Sharing"
    echo "3. Turn ON 'Remote Login'"
    echo "4. Make sure your user account is allowed"
    echo ""
    echo "Or run this command:"
    echo "sudo systemsetup -setremotelogin on"
    echo ""
    read -p "Press Enter after enabling SSH to continue..."
else
    echo "✅ SSH is already enabled"
fi

# Test local SSH
echo ""
echo "🧪 Testing local SSH..."
if ssh -o ConnectTimeout=2 localhost "echo 'Local SSH works!'" 2>/dev/null; then
    echo "✅ Local SSH connection successful"
else
    echo "❌ Local SSH test failed. Please check your SSH settings."
    exit 1
fi

# Test from VPS
echo ""
echo "🧪 Testing connection from VPS..."
if ssh vps "ssh -o ConnectTimeout=5 laptop 'echo Connected to MacBook via VPS!'" 2>/dev/null; then
    echo "✅ VPS to laptop connection works!"
else
    echo "⚠️  VPS connection not working yet. Checking reverse tunnel..."
    
    # Check if tunnel is running
    if ps aux | grep -q "[s]sh.*2222:localhost:22"; then
        echo "✅ Reverse tunnel is running"
        echo "🔧 Restarting SSH connection..."
        
        # Try to restart the tunnel
        launchctl kickstart -k gui/$(id -u)/com.user.reversetunnel 2>/dev/null || true
        
        sleep 3
        
        # Test again
        if ssh vps "ssh -o ConnectTimeout=5 laptop 'echo Connected!'" 2>/dev/null; then
            echo "✅ Connection fixed!"
        else
            echo "❌ Still not working. You may need to restart the reverse tunnel service."
        fi
    else
        echo "❌ Reverse tunnel not running. Please check your autossh setup."
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📱 QUICK SETUP FOR YOUR DEVICES:"
echo ""
echo "FOR ANDROID (Termux):"
echo "1. Install Termux from F-Droid (not Play Store)"
echo "2. Run in Termux:"
echo "   pkg install openssh"
echo "   ssh-keygen -t ed25519"
echo "   # Copy the public key"
echo "   cat ~/.ssh/id_ed25519.pub"
echo ""
echo "3. Add the public key to your VPS:"
echo "   ssh root@143.110.172.229"
echo "   # Paste the key into ~/.ssh/authorized_keys"
echo ""
echo "4. Create connection shortcut in Termux:"
echo "   echo 'ssh -t root@143.110.172.229 laptop' > ~/laptop"
echo "   chmod +x ~/laptop"
echo "   # Now just run: ./laptop"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "FOR YOUR OTHER MACBOOK:"
echo "Quick one-liner (no setup needed):"
echo "  ssh -t root@143.110.172.229 laptop"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"