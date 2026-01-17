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

  -- Get filetype
  local filetype = vim.filetype.match({ filename = filepath }) or ""

  -- Capture user's window settings before creating floating windows
  local user_number = vim.wo.number
  local user_relativenumber = vim.wo.relativenumber

  -- Create scratch buffer for HEAD content
  local head_bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[head_bufnr].buftype = "nofile"
  vim.bo[head_bufnr].bufhidden = "wipe"
  vim.api.nvim_buf_set_lines(head_bufnr, 0, -1, false, head_content or {})
  vim.bo[head_bufnr].modifiable = false
  vim.bo[head_bufnr].filetype = filetype

  -- Create scratch buffer for working file
  local work_bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[work_bufnr].buftype = "nofile"
  vim.bo[work_bufnr].bufhidden = "wipe"

  if working_exists then
    local work_content = vim.fn.readfile(full_path)
    vim.api.nvim_buf_set_lines(work_bufnr, 0, -1, false, work_content)
  else
    -- File deleted, show empty buffer
    vim.api.nvim_buf_set_lines(work_bufnr, 0, -1, false, {})
  end

  vim.bo[work_bufnr].modifiable = false
  vim.bo[work_bufnr].filetype = filetype

  -- Calculate window dimensions (80% of editor, split in half)
  local editor_width = vim.o.columns
  local editor_height = vim.o.lines
  local total_width = math.floor(editor_width * 0.8)
  local win_height = math.floor(editor_height * 0.8)
  local win_width = math.floor((total_width - 2) / 2)
  local start_col = math.floor((editor_width - total_width) / 2)
  local start_row = math.floor((editor_height - win_height) / 2)

  -- Create HEAD floating window (left)
  local left_win = vim.api.nvim_open_win(head_bufnr, false, {
    relative = "editor",
    width = win_width,
    height = win_height,
    row = start_row,
    col = start_col,
    style = "minimal",
    border = "rounded",
    title = " HEAD ",
    title_pos = "center",
  })

  -- Create working file floating window (right, focused)
  local right_win = vim.api.nvim_open_win(work_bufnr, true, {
    relative = "editor",
    width = win_width,
    height = win_height,
    row = start_row,
    col = start_col + win_width + 2,
    style = "minimal",
    border = "rounded",
    title = " Working ",
    title_pos = "center",
  })

  -- Enable line numbers
  vim.wo[left_win].number = user_number
  vim.wo[left_win].relativenumber = user_relativenumber
  vim.wo[right_win].number = user_number
  vim.wo[right_win].relativenumber = user_relativenumber

  -- Enable diff mode on both windows
  vim.api.nvim_set_current_win(left_win)
  vim.cmd("diffthis")
  vim.api.nvim_set_current_win(right_win)
  vim.cmd("diffthis")

  -- Close function
  local function close_diff()
    for _, win in ipairs({left_win, right_win}) do
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_set_current_win(win)
        vim.cmd("diffoff")
        vim.api.nvim_win_close(win, true)
      end
    end
  end

  -- Bind q, <Esc>, and o to both buffers
  for _, buf in ipairs({head_bufnr, work_bufnr}) do
    vim.keymap.set("n", "q", close_diff, { buffer = buf, nowait = true })
    vim.keymap.set("n", "<Esc>", close_diff, { buffer = buf, nowait = true })
    vim.keymap.set("n", "o", function()
      local cursor = vim.api.nvim_win_get_cursor(0)
      close_diff()
      vim.cmd("edit " .. vim.fn.fnameescape(full_path))
      vim.api.nvim_win_set_cursor(0, cursor)
    end, { buffer = buf, nowait = true })
  end

  -- Auto-cleanup when one window closes
  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(left_win),
    callback = function()
      if vim.api.nvim_win_is_valid(right_win) then
        vim.cmd("diffoff")
        vim.api.nvim_win_close(right_win, true)
      end
    end,
    once = true,
  })

  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(right_win),
    callback = function()
      if vim.api.nvim_win_is_valid(left_win) then
        vim.cmd("diffoff")
        vim.api.nvim_win_close(left_win, true)
      end
    end,
    once = true,
  })
end

--- Open file for editing
function M.edit()
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

  local full_path = git_root .. "/" .. entry.filename
  vim.cmd("edit " .. vim.fn.fnameescape(full_path))
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
