# Preventing Sleep - Quick Setup

Since you want to edit your machine while out, you need to prevent your MacBook from sleeping when plugged in.

## One-Time Setup (Do This Now)

Run these commands once in Terminal:

```bash
# Prevent sleep when plugged in (requires admin password)
sudo pmset -c sleep 0
sudo pmset -c disablesleep 1

# Verify settings
pmset -g | grep -E "sleep|disablesleep"
```

## What This Does

- **When plugged in**: MacBook never sleeps (screen can still turn off)
- **When on battery**: Normal sleep behavior (preserves battery)
- **Web terminal**: Always accessible when MacBook is charging

## Alternative: System Settings

If you prefer the GUI:
1. System Settings → Battery → Power Adapter
2. Turn ON "Prevent automatic sleeping when the display is off"

## Important Notes

- Your MacBook must be plugged in for web terminal to stay accessible
- Screen can still turn off (doesn't affect terminal)
- This only affects behavior when connected to power
- To undo: `sudo pmset -c sleep 1` and `sudo pmset -c disablesleep 0`

With this setup, you can access your terminal from anywhere as long as your MacBook is plugged in at home!