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
}

M.options = vim.deepcopy(M.defaults)

---@param opts table|nil
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

return M
