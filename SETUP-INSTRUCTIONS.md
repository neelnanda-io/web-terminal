# SSH Access Setup Instructions

## 🔒 Security Improvements Active
- **Fail2ban**: Protecting VPS from brute force attacks (5 attempts = 10 min ban)
- **SSH Agent Forwarding**: Your keys stay on your devices, not stored on VPS

---

## 💻 On This Mac (One-Time Setup)

### 1. Enable SSH Agent in Terminal
Add this to your `~/.zshrc`:
```bash
# Enable SSH agent
if [ -z "$SSH_AUTH_SOCK" ]; then
   eval "$(ssh-agent -s)"
fi

# Add your keys to the agent on startup
ssh-add ~/.ssh/vps 2>/dev/null
```

Then reload:
```bash
source ~/.zshrc
```

### 2. Update Your SSH Config
Edit `~/.ssh/config` and add `-A` flag to VPS connection:
```
Host vps
    HostName 143.110.172.229
    User root
    IdentityFile ~/.ssh/vps
    ForwardAgent yes    # Add this line
```

### 3. Test Connection
```bash
# This should work once you enable SSH on your Mac:
ssh vps laptop
```

---

## 💻 On Your Other MacBook

### 1. Create SSH Config
Add to `~/.ssh/config`:
```
# VPS with agent forwarding
Host vps-laptop
    HostName 143.110.172.229
    User root
    ForwardAgent yes
    RequestTTY yes
    RemoteCommand laptop

# Direct tmux sessions
Host tmux-*
    HostName 143.110.172.229
    User root
    ForwardAgent yes
    RequestTTY yes
    RemoteCommand laptop-tmux $(echo %n | cut -d- -f2-)
```

### 2. Add Your SSH Key to VPS
```bash
# Copy your public key
cat ~/.ssh/id_ed25519.pub  # or id_rsa.pub

# Add to VPS (one time)
ssh root@143.110.172.229 'echo "YOUR_PUBLIC_KEY" >> ~/.ssh/authorized_keys'
```

### 3. Use It
```bash
# Connect to laptop
ssh vps-laptop

# Connect to specific tmux session
ssh tmux-Code
ssh tmux-VPS
```

---

## 📱 On Android (Termius) - RECOMMENDED

### 1. Install Termius
- Download from Play Store (free version works)
- Create account (for syncing across devices)

### 2. Add VPS Host
- Tap **+ New Host**
- Label: `VPS`
- Hostname: `143.110.172.229`
- Port: `22`
- Username: `root`

### 3. Add SSH Key
- Go to **Keychain** (bottom menu)
- Tap **+** → **SSH Key**
- Either:
  - Generate new key pair, OR
  - Import existing key (paste private key)
- Name it (e.g., "VPS Key")

### 4. Link Key to Host
- Go back to **Hosts**
- Edit your VPS host
- Under **SSH**, select your key
- **IMPORTANT**: Turn ON **"Use Agent Forwarding"**

### 5. Create Snippets (Shortcuts)
- Connect to VPS first
- Tap the **≡** menu → **Snippets**
- Create these:
  
  **Snippet 1: "Laptop"**
  ```
  laptop
  ```
  
  **Snippet 2: "Tmux List"**
  ```
  laptop-tmux
  ```
  
  **Snippet 3: "Tmux Code"**
  ```
  laptop-tmux Code
  ```

### 6. Use It
- Connect to VPS
- Tap snippet to run command
- For even faster access: Long-press host → "Add to Home Screen"

---

## 📱 On Android (JuiceSSH)

### 1. Setup Connection
- Add new connection to `143.110.172.229`
- Use your existing identity/key
- **Enable "Forward Agent"** in connection settings

### 2. Create Snippets
After connecting, create these snippets:
- `laptop` → Connect to MacBook
- `laptop-tmux` → List sessions
- `laptop-tmux Code` → Connect to Code session

### 3. Use It
Just tap your connection and run the snippets!

---

## 📱 On Android (Termux)

### 1. Setup SSH Agent
```bash
# Install OpenSSH
pkg install openssh

# Start agent and add key
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Create connection script
cat > ~/laptop << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
ssh -A -t root@143.110.172.229 laptop
EOF
chmod +x ~/laptop
```

### 2. Use It
```bash
./laptop  # Connect to MacBook
```

---

## 🔍 How Agent Forwarding Works

1. **Your device** has your private SSH key
2. When you connect to VPS with `-A` flag, it creates a secure channel
3. When VPS connects to your laptop, it asks YOUR device to authenticate
4. Your private key never leaves your device!

Think of it like showing your ID through a window instead of handing it over.

---

## 🚨 Important Notes

1. **First enable SSH on your Mac**: System Settings → General → Sharing → Remote Login: ON

2. **The old method still works**: If agent forwarding fails, it falls back to the stored key

3. **Check fail2ban status**: 
   ```bash
   ssh vps 'fail2ban-client status sshd'
   ```

4. **If you get locked out by fail2ban** (5 wrong passwords):
   - Wait 10 minutes, or
   - Use the DigitalOcean console to unban yourself:
     ```bash
     fail2ban-client unban YOUR_IP
     ```