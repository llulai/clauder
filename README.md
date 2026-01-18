# clauder.nvim

Git modified files browser for Neovim

## Installation

```lua
{
  "yourusername/clauder.nvim",
  config = function()
    require("clauder").setup()
  end,
}
```

## Default Keymaps

| Key | Action |
|-----|--------|
| `<CR>`, `o` | Open diff view |
| `q`, `-` | Close clauder |
| `R`, `<C-l>` | Refresh file list |
| `g?` | Show help |

## Configuration

```lua
require("clauder").setup({
  keymaps = {
    ["<CR>"] = { action = "select", desc = "Open diff view" },
    ["o"] = { action = "select", desc = "Open diff view" },
    ["q"] = { action = "close", desc = "Close clauder" },
    ["-"] = { action = "close", desc = "Close clauder" },
    ["R"] = { action = "refresh", desc = "Refresh file list" },
    ["<C-l>"] = { action = "refresh", desc = "Refresh file list" },
    ["g?"] = { action = "help", desc = "Show help" },
  },
  diff = {
    vertical = true,
  },
})
```

## Usage

Open clauder with `:Clauder` command.

## Claude Dashboard

A tmux session picker that shows Claude Code session status across worktrees.

### Dependencies

- `jq` - JSON parsing
- `fzf` - fuzzy finder
- `tmux` - terminal multiplexer

### Setup

1. **Symlink scripts to PATH:**
   ```bash
   ln -sf ~/path/to/clauder/bin/claude-dashboard-hook ~/.local/bin/
   ln -sf ~/path/to/clauder/bin/claude-dashboard ~/.local/bin/
   ```

2. **Add hooks to `~/.claude/settings.json`:**
   ```json
   {
     "hooks": {
       "SessionStart": [
         {"hooks": [{"type": "command", "command": "claude-dashboard-hook"}]}
       ],
       "Notification": [
         {
           "matcher": "permission_prompt|idle_prompt",
           "hooks": [{"type": "command", "command": "claude-dashboard-hook"}]
         }
       ],
       "UserPromptSubmit": [
         {"hooks": [{"type": "command", "command": "claude-dashboard-hook"}]}
       ],
       "Stop": [
         {"hooks": [{"type": "command", "command": "claude-dashboard-hook"}]}
       ]
     }
   }
   ```

### Usage

Run `claude-dashboard` to open fzf picker showing all Claude sessions:
- ⚠️ = waiting for input/permission
- 🔧 = working
- ⏸️ = stopped

Select a session to switch to that tmux session and focus the Claude pane.

### Tmux Popup Integration

Open the dashboard in a floating popup (recommended):

```tmux
# Add to ~/.tmux.conf
bind-key C display-popup -E -w 80% -h 80% "claude-dashboard"
```

Reload tmux config (from within tmux):
```tmux
:source ~/.tmux.conf
```

Or from shell:
```bash
tmux source-file ~/.tmux.conf
```

Press `prefix + C` to open the dashboard popup, select a session, and automatically switch + focus the Claude pane.
