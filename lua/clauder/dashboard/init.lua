local state = require("clauder.dashboard.state")
local view = require("clauder.dashboard.view")
local actions = require("clauder.dashboard.actions")
local config = require("clauder.config")
local util = require("clauder.util")

local M = {}

--- Open Claude session dashboard
function M.open()
  -- Get sessions
  local sessions = state.get_sessions()

  -- Open floating window
  local bufnr, _ = view.open_float(sessions)

  -- Setup keymaps
  local keymaps = {}
  for key, mapping in pairs(config.options.dashboard.keymaps) do
    keymaps[key] = {
      callback = actions[mapping.action],
      desc = mapping.desc,
    }
  end

  util.set_keymaps(keymaps, bufnr)
end

return M
