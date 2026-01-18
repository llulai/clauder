local M = {}

local util = require("clauder.util")

--- Get git root directory
--- @return string|nil git_root or nil if not in git repo
local function get_git_root()
  local result = util.system("git rev-parse --show-toplevel")
  if result.code == 0 and #result.stdout > 0 then
    return result.stdout[1]
  end
  return nil
end

--- Calculate relative path from git root
--- @param filepath string Absolute file path
--- @param git_root string Git root directory
--- @return string Relative path
local function get_relative_path(filepath, git_root)
  -- Normalize paths by removing trailing slashes
  git_root = git_root:gsub("/$", "")

  -- If filepath starts with git_root, remove it
  if filepath:find(git_root, 1, true) == 1 then
    local relative = filepath:sub(#git_root + 2) -- +2 to skip the trailing /
    return relative
  end

  -- Fallback to full path if not under git root
  return filepath
end

--- Copy file reference to clipboard
--- Called with visual selection range
function M.copy_reference()
  -- Get visual selection range
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")

  -- Get current file path
  local filepath = vim.fn.expand("%:p")

  -- Check if file exists (not a scratch buffer)
  if filepath == "" then
    vim.notify("No file associated with current buffer", vim.log.levels.WARN)
    return
  end

  -- Get git root and calculate relative path
  local git_root = get_git_root()
  local display_path = filepath

  if git_root then
    display_path = get_relative_path(filepath, git_root)
  end

  -- Format reference
  local reference
  if start_line == end_line then
    reference = string.format("%s:%d", display_path, start_line)
  else
    reference = string.format("%s:%d-%d", display_path, start_line, end_line)
  end

  -- Copy to system clipboard (+ register)
  vim.fn.setreg("+", reference)

  -- Notify user
  vim.notify("Copied: " .. reference, vim.log.levels.INFO)
end

return M
