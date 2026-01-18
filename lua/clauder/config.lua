local M = {}

M.defaults = {
  buf_options = {
    buftype = "nofile",
    buflisted = false,
    swapfile = false,
  },
  win_options = {
    wrap = false,
    signcolumn = "no",
    cursorline = true,
  },
  keymaps = {
    ["<CR>"] = { action = "select", desc = "Open diff view" },
    ["o"] = { action = "edit", desc = "Edit file" },
    ["q"] = { action = "close", desc = "Close clauder" },
    ["-"] = { action = "close", desc = "Close clauder" },
    ["R"] = { action = "refresh", desc = "Refresh file list" },
    ["<C-l>"] = { action = "refresh", desc = "Refresh file list" },
    ["g?"] = { action = "help", desc = "Show help" },
  },
  diff = {
    vertical = true,
  },
  dashboard = {
    state_dir = "~/.claude-dashboard",
    keymaps = {
      ["<CR>"] = { action = "select", desc = "Switch to session" },
      ["q"] = { action = "close", desc = "Close dashboard" },
      ["<Esc>"] = { action = "close", desc = "Close dashboard" },
      ["R"] = { action = "refresh", desc = "Refresh sessions" },
    },
    status_icons = {
      waiting_input = "⚠️",
      working = "▶",
      stopped = "⏸",
    },
  },
}

M.options = vim.deepcopy(M.defaults)

---@param opts table|nil
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

return M
