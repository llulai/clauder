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
