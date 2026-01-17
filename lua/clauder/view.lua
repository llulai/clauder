local config = require("clauder.config")

local M = {}

-- Entry cache: bufnr -> entries[]
M._cache = {}

--- Initialize buffer with options
---@param bufnr number
function M.initialize(bufnr)
  -- Set buffer options
  for option, value in pairs(config.options.buf_options) do
    vim.bo[bufnr][option] = value
  end

  -- Set filetype
  vim.bo[bufnr].filetype = "clauder"

  -- Set window options
  for option, value in pairs(config.options.win_options) do
    vim.wo[option] = value
  end
end

--- Render file list in buffer
---@param bufnr number
---@param entries {filename: string, status: string}[]
function M.render(bufnr, entries)
  -- Store entries in cache
  M._cache[bufnr] = entries

  -- Build lines
  local lines = {}
  for _, entry in ipairs(entries) do
    local line = string.format("%s  %s", entry.status, entry.filename)
    table.insert(lines, line)
  end

  -- If no entries, show message
  if #lines == 0 then
    lines = { "No modified files" }
  end

  -- Set lines in buffer
  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].modifiable = false
  vim.bo[bufnr].modified = false
end

--- Get entry data for line under cursor
---@param bufnr number
---@param lnum number|nil Line number (defaults to cursor line)
---@return {filename: string, status: string}|nil
function M.get_entry_on_line(bufnr, lnum)
  lnum = lnum or vim.fn.line(".")
  local entries = M._cache[bufnr]

  if not entries or #entries == 0 then
    return nil
  end

  -- Entries are 1-indexed, lines are 1-indexed
  return entries[lnum]
end

--- Clear cache for buffer
---@param bufnr number
function M.clear_cache(bufnr)
  M._cache[bufnr] = nil
end

return M
