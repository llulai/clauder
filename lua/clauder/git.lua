local util = require("clauder.util")

local M = {}

--- Find the git root directory
---@param path string|nil Path to start searching from (defaults to cwd)
---@return string|nil Git root path or nil if not in a git repo
function M.get_git_root(path)
  path = path or vim.fn.getcwd()
  local result = util.system("git rev-parse --show-toplevel", path)

  if result.code ~= 0 then
    return nil
  end

  return vim.trim(result.stdout)
end

--- Get diff statistics for files
---@param cwd string|nil Working directory (defaults to git root)
---@return table<string, {added: number, removed: number}>
function M.get_diff_stats(cwd)
  cwd = cwd or M.get_git_root()

  if not cwd then
    return {}
  end

  local stats = {}

  -- Get unstaged changes
  local result_unstaged = util.system("git diff --numstat", cwd)
  if result_unstaged.code == 0 then
    for line in result_unstaged.stdout:gmatch("[^\r\n]+") do
      if line ~= "" then
        local added, removed, filename = line:match("^(%d+)%s+(%d+)%s+(.+)$")
        if added and removed and filename then
          stats[filename] = {
            added = tonumber(added) or 0,
            removed = tonumber(removed) or 0,
          }
        end
      end
    end
  end

  -- Get staged changes
  local result_staged = util.system("git diff --numstat --cached", cwd)
  if result_staged.code == 0 then
    for line in result_staged.stdout:gmatch("[^\r\n]+") do
      if line ~= "" then
        local added, removed, filename = line:match("^(%d+)%s+(%d+)%s+(.+)$")
        if added and removed and filename then
          local existing = stats[filename]
          if existing then
            -- Combine staged and unstaged stats
            stats[filename] = {
              added = existing.added + (tonumber(added) or 0),
              removed = existing.removed + (tonumber(removed) or 0),
            }
          else
            stats[filename] = {
              added = tonumber(added) or 0,
              removed = tonumber(removed) or 0,
            }
          end
        end
      end
    end
  end

  return stats
end

--- Get list of modified files in the working tree
---@param cwd string|nil Working directory (defaults to git root)
---@return {filename: string, status: string, added: number, removed: number}[]
function M.get_modified_files(cwd)
  cwd = cwd or M.get_git_root()

  if not cwd then
    return {}
  end

  local result = util.system("git status --porcelain", cwd)

  if result.code ~= 0 then
    return {}
  end

  -- Get diff stats for all files
  local stats = M.get_diff_stats(cwd)

  local files = {}
  for line in result.stdout:gmatch("[^\r\n]+") do
    if line ~= "" then
      -- Format: "XY filename"
      -- X = staged status, Y = working tree status
      local status = line:sub(1, 2)
      local filename = line:sub(4)

      -- Expand untracked directories into individual files
      if status == "??" then
        -- Remove trailing slash from directory names
        local clean_filename = filename:gsub("/$", "")
        local full_path = cwd .. "/" .. clean_filename

        if vim.fn.isdirectory(full_path) == 1 then
          -- Get all files in directory recursively
          local files_in_dir = vim.fn.glob(full_path .. "/**/*", false, true)
          for _, file in ipairs(files_in_dir) do
            if vim.fn.isdirectory(file) == 0 then
              local relative = file:sub(#cwd + 2)  -- Remove cwd prefix + "/"

              -- Count lines in untracked file
              local line_count = 0
              local file_handle = io.open(file, "r")
              if file_handle then
                for _ in file_handle:lines() do
                  line_count = line_count + 1
                end
                file_handle:close()
              end

              table.insert(files, {
                filename = relative,
                status = "??",
                added = line_count,
                removed = 0,
              })
            end
          end
        else
          -- It's an untracked file
          -- Count lines in untracked file
          local line_count = 0
          local file_handle = io.open(full_path, "r")
          if file_handle then
            for _ in file_handle:lines() do
              line_count = line_count + 1
            end
            file_handle:close()
          end

          table.insert(files, {
            filename = clean_filename,
            status = status,
            added = line_count,
            removed = 0,
          })
        end
      else
        -- Tracked file (modified, added, deleted, etc.)
        local file_stats = stats[filename] or { added = 0, removed = 0 }
        table.insert(files, {
          filename = filename,
          status = status,
          added = file_stats.added,
          removed = file_stats.removed,
        })
      end
    end
  end

  return files
end

--- Get file content from HEAD
---@param filepath string Relative path to file
---@param cwd string|nil Working directory (defaults to git root)
---@return string[]|nil Lines of file content from HEAD, or nil if error
function M.get_head_content(filepath, cwd)
  cwd = cwd or M.get_git_root()

  if not cwd then
    return nil
  end

  local result = util.system({ "git", "show", "HEAD:" .. filepath }, cwd)

  if result.code ~= 0 then
    return nil
  end

  local lines = {}
  for line in result.stdout:gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end

  -- Handle empty files
  if #lines == 0 and result.stdout ~= "" then
    return { "" }
  end

  return lines
end

return M
