# Web Terminal Access

## Access the Terminal

Go to: http://143.110.172.229/

**Login credentials:**
- Username: `admin`
- Password: `feet-essential-wherever-principle`

**Alternative URL with credentials:**
http://admin:feet-essential-wherever-principle@143.110.172.229/

## If Authentication Fails

1. Clear browser cache/cookies for the site
2. Try in incognito/private browsing mode
3. Use the alternative URL format above

## Other Pages

- Sessions list: http://143.110.172.229/sessions
- Mobile interface: http://143.110.172.229/mobile

## SSH Access (Alternative)

From any device with SSH:
```bash
# Direct SSH to laptop
ssh -t root@143.110.172.229 laptop

# Access specific tmux session
ssh -t root@143.110.172.229 laptop-tmux Code
```

## Troubleshooting

If the web terminal shows a blank page or authentication issues:

1. The password was changed from having spaces to using hyphens for browser compatibility
2. Some browsers have issues with Basic Authentication containing special characters
3. The SSH method is more reliable for command-line access

## Technical Details

- ttyd runs on your laptop and exposes terminal over WebSocket
- Reverse SSH tunnel forwards port 7681 to VPS
- nginx on VPS proxies requests to ttyd
- Authentication uses HTTP Basic Auth