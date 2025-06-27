# Mobile Terminal Usage Guide

Since browser security prevents direct keyboard injection into iframes, here's the practical solution for mobile terminal usage:

## Quick Access URLs

- **Main Terminal**: http://143.110.172.229/
- **Terminal Overview**: http://143.110.172.229/terminals
- **Copy Helper**: http://143.110.172.229/simple

## Working with tmux Sessions

### Method 1: Direct tmux Commands

Open the terminal and type/paste these commands:

```bash
# Create named sessions in specific directories
tmux new -s code -c ~/Code
tmux new -s projects -c ~/Projects  
tmux new -s docs -c ~/Documents

# List all sessions
tmux ls

# Switch between sessions (while in tmux)
tmux switch -t code
tmux switch -t projects

# Or use Ctrl+B, then S to see session list
```

### Method 2: Use the Quick Script

```bash
# The script is at ~/quick-terminal.sh
./quick-terminal.sh code      # Opens/switches to Code session
./quick-terminal.sh projects  # Opens/switches to Projects session
./quick-terminal.sh documents # Opens/switches to Documents session
```

## Mobile Tips

### For Tab Completion
- Type the first few letters
- Copy `	` (tab character) from the helper page
- Paste it after your partial command

### For Command History  
- Use `history | grep keyword` to find commands
- Or `!123` to run command #123 from history

### For New Lines
- Use **Option+Enter** (not Shift+Enter)
- Shift+Enter submits the command

### Tmux Window Management
Within a tmux session:
- `Ctrl+B, C` - Create new window
- `Ctrl+B, N` - Next window  
- `Ctrl+B, P` - Previous window
- `Ctrl+B, 0-9` - Switch to window by number
- `Ctrl+B, W` - List all windows

### Tmux Pane Management
- `Ctrl+B, %` - Split vertically
- `Ctrl+B, "` - Split horizontally
- `Ctrl+B, O` - Switch between panes
- `Ctrl+B, arrows` - Navigate panes

## Workflow Example

1. Open terminal: http://143.110.172.229/
2. Create a Code session: `tmux new -s code -c ~/Code`
3. Work in that directory
4. Create another session: `tmux new -s docs -c ~/Documents`
5. Switch between them: `tmux switch -t code`
6. Open new browser tabs for parallel work

Each browser tab can attach to a different tmux session, giving you multiple workspaces.

## Copy/Paste Workflow

1. Visit http://143.110.172.229/simple
2. Click buttons to copy commands
3. Return to terminal and paste with Cmd+V

## Troubleshooting

If terminal is unresponsive:
- Refresh the page
- Check if you're in a tmux session: look for green bar at bottom
- Detach from tmux: `Ctrl+B, D`
- Kill stuck session: `tmux kill-session -t session-name`