local config = require("clauder.config")
local git = require("clauder.git")
local view = require("clauder.view")
local actions = require("clauder.actions")
local util = require("clauder.util")

local M = {}

-- Track the clauder buffer
M._bufnr = nil

--- Setup plugin with user configuration
---@param opts table|nil User configuration
function M.setup(opts)
  config.setup(opts)
end

--- Open clauder buffer with git modified files
function M.open()
  -- Check if already open
  if M._bufnr and vim.api.nvim_buf_is_valid(M._bufnr) then
    vim.api.nvim_set_current_buf(M._bufnr)
    return
  end

  -- Get git root
  local git_root = git.get_git_root()
  if not git_root then
    vim.notify("Not in a git repository", vim.log.levels.ERROR)
    return
  end

  -- Get modified files
  local entries = git.get_modified_files(git_root)

  -- Create buffer
  local bufnr = vim.api.nvim_create_buf(false, true)
  M._bufnr = bufnr

  -- Initialize view
  view.initialize(bufnr)

  -- Render entries
  view.render(bufnr, entries)

  -- Set up keymaps
  local keymaps = {}
  for key, mapping in pairs(config.options.keymaps) do
    local action = mapping.action
    local callback

    if action == "select" then
      callback = actions.select
    elseif action == "close" then
      callback = actions.close
    elseif action == "refresh" then
      callback = actions.refresh
    elseif action == "help" then
      callback = actions.help
    end

    if callback then
      keymaps[key] = {
        callback = callback,
        desc = mapping.desc,
      }
    end
  end

  util.set_keymaps(keymaps, bufnr)

  -- Clean up on buffer delete
  vim.api.nvim_create_autocmd("BufDelete", {
    buffer = bufnr,
    callback = function()
      view.clear_cache(bufnr)
      M._bufnr = nil
    end,
  })

  -- Switch to the buffer (replaces current window like oil.nvim)
  vim.api.nvim_set_current_buf(bufnr)
end

--- Close clauder buffer
function M.close()
  actions.close()
end

--- Refresh clauder buffer
function M.refresh()
  actions.refresh()
end

--- Get entry under cursor
---@return {filename: string, status: string}|nil
function M.get_cursor_entry()
  if not M._bufnr or not vim.api.nvim_buf_is_valid(M._bufnr) then
    return nil
  end

  return view.get_entry_on_line(M._bufnr)
end

return M
