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

  -- Define highlight groups
  vim.api.nvim_set_hl(0, "ClauderAdd", { link = "diffAdded" })
  vim.api.nvim_set_hl(0, "ClauderRemove", { link = "diffRemoved" })
end

--- Render file list in buffer
---@param bufnr number
---@param entries {filename: string, status: string, added: number, removed: number}[]
function M.render(bufnr, entries)
  -- Store entries in cache
  M._cache[bufnr] = entries

  -- First pass: find max widths
  local max_add = 0
  local max_rem = 0
  for _, entry in ipairs(entries) do
    local add_width = #tostring(entry.added)
    local rem_width = #tostring(entry.removed)
    if add_width > max_add then
      max_add = add_width
    end
    if rem_width > max_rem then
      max_rem = rem_width
    end
  end

  -- Build lines with padding
  local lines = {}
  for _, entry in ipairs(entries) do
    local line = string.format("+%" .. max_add .. "d/-%" .. max_rem .. "d  %s",
                               entry.added, entry.removed, entry.filename)
    table.insert(lines, line)
  end

  -- If no entries, show message
  if #lines == 0 then
    lines = { "No modified files" }
  end

  -- Set lines in buffer
  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

  -- Apply highlights with fixed positions
  for i, line in ipairs(lines) do
    if line ~= "No modified files" then
      -- +X spans from 0 to (1 + max_add)
      local add_end = 1 + max_add
      -- -Y starts after "/" which is at position add_end + 1
      local rem_start = add_end + 1
      local rem_end = rem_start + 1 + max_rem

      -- Highlight +X
      vim.api.nvim_buf_add_highlight(bufnr, -1, "ClauderAdd", i - 1, 0, add_end)

      -- Highlight -Y
      vim.api.nvim_buf_add_highlight(bufnr, -1, "ClauderRemove", i - 1, rem_start, rem_end)
    end
  end

  vim.bo[bufnr].modifiable = false
  vim.bo[bufnr].modified = false
end

--- Get entry data for line under cursor
---@param bufnr number
---@param lnum number|nil Line number (defaults to cursor line)
---@return {filename: string, status: string, added: number, removed: number}|nil
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
