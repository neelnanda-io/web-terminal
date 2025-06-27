#!/bin/bash
# Example credentials file - Copy to credentials.sh and update with your values
# NEVER commit the actual credentials.sh file!

# ttyd authentication (change these!)
export TTYD_USERNAME="admin"
export TTYD_PASSWORD="your-secure-password-here"

# VPS connection details (update with your server info)
export VPS_HOST="your-vps-hostname"
export VPS_USER="your-vps-username"
export VPS_PORT="22"

# Local ports
export TTYD_PORT="7681"
export REVERSE_TUNNEL_PORT="7681"

# SSH key path (if using key-based auth)
export SSH_KEY_PATH="$HOME/.ssh/id_rsa"