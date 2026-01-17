local M = {}

--- Execute a shell command and return the result
---@param cmd string|string[] Command to execute
---@param cwd string|nil Working directory
---@return {stdout: string, stderr: string, code: number}
function M.system(cmd, cwd)
  local command = type(cmd) == "table" and table.concat(cmd, " ") or cmd

  if cwd then
    command = string.format("cd %s && %s", vim.fn.shellescape(cwd), command)
  end

  local output = vim.fn.systemlist(command)
  local code = vim.v.shell_error

  -- Join output lines
  local stdout = table.concat(output, "\n")

  return {
    stdout = stdout,
    stderr = code ~= 0 and stdout or "",
    code = code,
  }
end

--- Set buffer-local keymaps
---@param keymaps table<string, {callback: function, desc: string}>
---@param bufnr number
function M.set_keymaps(keymaps, bufnr)
  for key, mapping in pairs(keymaps) do
    vim.keymap.set("n", key, mapping.callback, {
      buffer = bufnr,
      noremap = true,
      silent = true,
      desc = mapping.desc,
    })
  end
end

return M
