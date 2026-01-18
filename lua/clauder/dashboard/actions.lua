local util = require("clauder.util")
local view = require("clauder.dashboard.view")
local state = require("clauder.dashboard.state")

local M = {}

--- Find and focus the pane running Claude Code
--- Ports the ps/tty matching logic from bash script
local function find_and_focus_claude_pane()
  -- Check if we're in tmux
  local tmux_check = util.system("tmux display-message -p '#S' 2>/dev/null")
  if tmux_check.code ~= 0 then
    return
  end

  -- Get all panes with their IDs and TTYs
  local panes_result = util.system("tmux list-panes -a -F '#{pane_id} #{pane_tty}'")
  if panes_result.code ~= 0 then
    return
  end

  -- Parse panes
  local panes = {}
  for line in panes_result.stdout:gmatch("[^\r\n]+") do
    local pane_id, tty = line:match("^(%S+)%s+(%S+)$")
    if pane_id and tty then
      table.insert(panes, { id = pane_id, tty = tty })
    end
  end

  -- Find pane running claude
  for _, pane in ipairs(panes) do
    -- Get process command for this TTY
    local ps_result = util.system("ps -t " .. pane.tty .. " -o comm= | grep -E 'claude|node' | head -1")
    if ps_result.code == 0 and ps_result.stdout:match("%S") then
      -- Found Claude pane, select it
      util.system("tmux select-pane -t " .. pane.id)
      return
    end
  end
end

--- Switch to selected session
function M.select()
  local bufnr = vim.api.nvim_get_current_buf()
  local session = view.get_entry_on_line(bufnr)

  if not session then
    vim.notify("No session selected", vim.log.levels.WARN)
    return
  end

  -- Check if tmux is available
  local tmux_check = util.system("command -v tmux")
  if tmux_check.code ~= 0 then
    vim.notify("tmux not found", vim.log.levels.ERROR)
    return
  end

  -- Close dashboard first
  M.close()

  -- Switch to tmux session
  local result = util.system("tmux switch-client -t " .. vim.fn.shellescape(session.worktree))
  if result.code ~= 0 then
    vim.notify("Failed to switch to session: " .. session.worktree, vim.log.levels.ERROR)
    return
  end

  -- Auto-focus Claude pane
  find_and_focus_claude_pane()
end

--- Close dashboard window
function M.close()
  local winid = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_is_valid(winid) then
    vim.api.nvim_win_close(winid, true)
  end
end

--- Refresh dashboard
function M.refresh()
  local bufnr = vim.api.nvim_get_current_buf()
  local winid = vim.api.nvim_get_current_win()

  -- Close current window
  if vim.api.nvim_win_is_valid(winid) then
    vim.api.nvim_win_close(winid, true)
  end

  -- Re-read state and open new window
  local sessions = state.get_sessions()
  view.open_float(sessions)

  vim.notify("Refreshed", vim.log.levels.INFO)
end

return M
