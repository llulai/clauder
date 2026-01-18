local M = {}
local util = require("clauder.util")

--- Read and parse all Claude dashboard JSON files
---@return {worktree: string, status: string, message: string, cwd: string, last_update: number}[]
function M.get_sessions()
  local home = vim.fn.expand("~")
  local state_dir = home .. "/.claude-dashboard"

  -- Check if directory exists
  if vim.fn.isdirectory(state_dir) == 0 then
    return {}
  end

  -- Glob all .json files
  local json_files = vim.fn.glob(state_dir .. "/*.json", false, true)

  local sessions = {}
  for _, filepath in ipairs(json_files) do
    -- Read file
    local file = io.open(filepath, "r")
    if file then
      local content = file:read("*all")
      file:close()

      -- Parse JSON
      local ok, data = pcall(vim.json.decode, content)
      if ok and data then
        table.insert(sessions, {
          worktree = data.worktree or "",
          status = data.status or "stopped",
          message = data.message or "",
          cwd = data.cwd or "",
          last_update = data.last_update or 0,
        })
      end
    end
  end

  -- Filter sessions by active tmux sessions
  local tmux_result = util.system("tmux list-sessions -F '#{session_name}' 2>/dev/null")
  local active_tmux = {}
  if tmux_result.code == 0 then
    for line in tmux_result.stdout:gmatch("[^\r\n]+") do
      active_tmux[line] = true
    end
  end

  sessions = vim.tbl_filter(function(s)
    return active_tmux[s.worktree]
  end, sessions)

  -- Sort: waiting_input first, then working, then stopped
  local status_priority = {
    waiting_input = 1,
    working = 2,
    stopped = 3,
  }

  table.sort(sessions, function(a, b)
    local a_priority = status_priority[a.status] or 99
    local b_priority = status_priority[b.status] or 99
    if a_priority ~= b_priority then
      return a_priority < b_priority
    end
    -- Secondary sort by worktree name
    return a.worktree < b.worktree
  end)

  return sessions
end

return M
