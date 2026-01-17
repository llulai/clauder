local git = require("clauder.git")
local view = require("clauder.view")
local config = require("clauder.config")

local M = {}

--- Open diff view for selected file
function M.select()
  local bufnr = vim.api.nvim_get_current_buf()
  local entry = view.get_entry_on_line(bufnr)

  if not entry then
    vim.notify("No file selected", vim.log.levels.WARN)
    return
  end

  local git_root = git.get_git_root()
  if not git_root then
    vim.notify("Not in a git repository", vim.log.levels.ERROR)
    return
  end

  local filepath = entry.filename
  local full_path = git_root .. "/" .. filepath

  -- Check if file exists in working tree
  local working_exists = vim.fn.filereadable(full_path) == 1

  -- Get HEAD content
  local head_content = git.get_head_content(filepath, git_root)

  -- Handle deleted files
  if not working_exists and not head_content then
    vim.notify("File does not exist in working tree or HEAD", vim.log.levels.ERROR)
    return
  end

  -- Create scratch buffer for HEAD content
  local head_bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[head_bufnr].buftype = "nofile"
  vim.bo[head_bufnr].bufhidden = "wipe"

  if head_content then
    vim.api.nvim_buf_set_lines(head_bufnr, 0, -1, false, head_content)
  else
    -- New file, HEAD is empty
    vim.api.nvim_buf_set_lines(head_bufnr, 0, -1, false, {})
  end

  vim.bo[head_bufnr].modifiable = false
  vim.bo[head_bufnr].filetype = vim.filetype.match({ filename = filepath }) or ""

  -- Open working file in current window (or create empty buffer for deleted files)
  if working_exists then
    vim.cmd("edit " .. vim.fn.fnameescape(full_path))
  else
    -- File deleted, show empty buffer
    local work_bufnr = vim.api.nvim_create_buf(false, true)
    vim.bo[work_bufnr].buftype = "nofile"
    vim.bo[work_bufnr].bufhidden = "wipe"
    vim.api.nvim_buf_set_lines(work_bufnr, 0, -1, false, {})
    vim.bo[work_bufnr].modifiable = false
    vim.bo[work_bufnr].filetype = vim.filetype.match({ filename = filepath }) or ""
    vim.api.nvim_set_current_buf(work_bufnr)
  end

  -- Open HEAD buffer in vertical split on the left
  if config.options.diff.vertical then
    vim.cmd("vertical leftabove sbuffer " .. head_bufnr)
  else
    vim.cmd("leftabove sbuffer " .. head_bufnr)
  end

  -- Enable diff mode on both windows
  vim.cmd("diffthis")
  vim.cmd("wincmd p") -- Move to working file window
  vim.cmd("diffthis")
end

--- Close clauder buffer
function M.close()
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.bo[bufnr].filetype == "clauder" then
    view.clear_cache(bufnr)
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end
end

--- Refresh file list
function M.refresh()
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.bo[bufnr].filetype ~= "clauder" then
    return
  end

  local git_root = git.get_git_root()
  if not git_root then
    vim.notify("Not in a git repository", vim.log.levels.ERROR)
    return
  end

  local entries = git.get_modified_files(git_root)
  view.render(bufnr, entries)

  vim.notify("Refreshed", vim.log.levels.INFO)
end

--- Show help
function M.help()
  local lines = {
    "Clauder - Git Modified Files Browser",
    "",
    "Keymaps:",
  }

  for key, mapping in pairs(config.options.keymaps) do
    table.insert(lines, string.format("  %-10s %s", key, mapping.desc))
  end

  -- Create floating window for help
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  local width = 50
  local height = #lines
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = (vim.o.columns - width) / 2,
    row = (vim.o.lines - height) / 2,
    style = "minimal",
    border = "rounded",
  })

  -- Close on any key
  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf, nowait = true })

  vim.keymap.set("n", "<CR>", function()
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf, nowait = true })
end

return M
