-- Prevent loading file twice
if vim.g.loaded_clauder then
  return
end
vim.g.loaded_clauder = true

-- Register :Clauder command
vim.api.nvim_create_user_command("Clauder", function()
  require("clauder").open()
end, {
  desc = "Open Clauder git modified files browser",
})

-- Register :ClauderCopy command (for visual mode)
vim.api.nvim_create_user_command("ClauderCopy", function()
  require("clauder.reference").copy_reference()
end, {
  range = true,
  desc = "Copy file reference with line numbers to clipboard",
})
