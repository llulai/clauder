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
