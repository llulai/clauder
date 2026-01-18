local config = require("clauder.config")

local M = {}

-- Entry cache: bufnr -> sessions[]
M._cache = {}

--- Define highlight groups
function M.setup_highlights()
  vim.api.nvim_set_hl(0, "ClauderWaiting", { fg = "#fabd2f", bold = true })  -- yellow
  vim.api.nvim_set_hl(0, "ClauderWorking", { fg = "#b8bb26", bold = true })  -- green
  vim.api.nvim_set_hl(0, "ClauderStopped", { fg = "#928374", bold = true })  -- gray
end

--- Open floating window with session list
---@param sessions {worktree: string, status: string, message: string, cwd: string, last_update: number}[]
---@return number bufnr, number winid
function M.open_float(sessions)
  -- Store sessions in cache
  local bufnr = vim.api.nvim_create_buf(false, true)
  M._cache[bufnr] = sessions

  -- Setup highlights
  M.setup_highlights()

  -- Get status icons from config
  local icons = config.options.dashboard.status_icons

  -- Build lines
  local lines = {}
  local max_worktree_len = 0

  -- First pass: calculate max worktree length
  for _, session in ipairs(sessions) do
    if #session.worktree > max_worktree_len then
      max_worktree_len = #session.worktree
    end
  end

  -- Second pass: format lines with padding
  for _, session in ipairs(sessions) do
    local icon = icons[session.status] or icons.stopped
    local worktree_padded = session.worktree .. string.rep(" ", max_worktree_len - #session.worktree)
    local line = string.format("%s  %-" .. max_worktree_len .. "s     %s",
                               icon, worktree_padded, session.message)
    table.insert(lines, line)
  end

  if #lines == 0 then
    lines = { "No active Claude sessions" }
  end

  -- Set buffer content
  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].modifiable = false
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].filetype = "claude-dashboard"

  -- Calculate window size
  local width = math.max(60, max_worktree_len + 40)
  local height = math.min(#lines, 20)

  -- Create centered floating window
  local winid = vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = "rounded",
    title = " Claude Sessions ",
    title_pos = "center",
  })

  -- Set window options
  vim.wo[winid].cursorline = true

  -- Apply highlights
  for i, session in ipairs(sessions) do
    local hl_group = "ClauderStopped"
    if session.status == "waiting_input" then
      hl_group = "ClauderWaiting"
    elseif session.status == "working" then
      hl_group = "ClauderWorking"
    end

    -- Highlight the icon (first 2 characters)
    vim.api.nvim_buf_add_highlight(bufnr, -1, hl_group, i - 1, 0, 2)
  end

  -- Auto-cleanup on buffer delete
  vim.api.nvim_create_autocmd("BufDelete", {
    buffer = bufnr,
    callback = function()
      M.clear_cache(bufnr)
    end,
    once = true,
  })

  return bufnr, winid
end

--- Get session data for line under cursor
---@param bufnr number
---@param lnum number|nil Line number (defaults to cursor line)
---@return {worktree: string, status: string, message: string, cwd: string, last_update: number}|nil
function M.get_entry_on_line(bufnr, lnum)
  lnum = lnum or vim.fn.line(".")
  local sessions = M._cache[bufnr]

  if not sessions or #sessions == 0 then
    return nil
  end

  return sessions[lnum]
end

--- Clear cache for buffer
---@param bufnr number
function M.clear_cache(bufnr)
  M._cache[bufnr] = nil
end

return M
