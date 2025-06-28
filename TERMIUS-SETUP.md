# Termius Setup for Android

## Quick Setup

1. **Install Termius** from Google Play Store

2. **Add New Host**:
   - Tap `+ New Host`
   - Label: `VPS Terminal`
   - Hostname: `143.110.172.229`
   - Port: `22`
   - Username: `root`

3. **Add SSH Key**:
   - Go to **Keychain** (bottom menu)
   - Tap **+** → **Generate Key**
   - Name: `VPS Key`
   - Type: `Ed25519`
   - Generate and copy the public key

4. **Add Key to VPS** (do this from your Mac):
   ```bash
   ssh vps 'echo "PASTE_PUBLIC_KEY_HERE" >> ~/.ssh/authorized_keys'
   ```

5. **Link Key to Host**:
   - Go back to **Hosts**
   - Edit `VPS Terminal`
   - Under **SSH**, select `VPS Key`
   - **IMPORTANT**: Turn ON **"Agent Forwarding"**

6. **Create Quick Actions**:
   After connecting, tap **≡** → **Snippets**

   **Snippet: "Mac Terminal"**
   ```
   laptop
   ```

   **Snippet: "List Sessions"**
   ```
   laptop-tmux
   ```

   **Snippet: "Code Session"**
   ```
   laptop-tmux Code
   ```

7. **Add to Home Screen** (optional):
   - Long press the host
   - Select "Add to Home Screen"
   - Name it "Mac Terminal"

## Usage

1. Tap your VPS host to connect
2. Tap a snippet to run the command
3. You're now in your Mac terminal!

## Troubleshooting

**"Permission denied"**
- Make sure you added your public key to the VPS
- Check that the key is selected in host settings

**"Connection refused"**
- Check your internet connection
- Verify the VPS IP is correct: 143.110.172.229

**Can't see tmux sessions**
- Make sure agent forwarding is enabled
- Try disconnecting and reconnecting

## Alternative: Direct Command

You can also create a host that connects directly:

1. **New Host** with same settings as above
2. Under **Advanced** → **Run Command**:
   ```
   laptop-tmux Code
   ```
3. This will connect directly to your Code session