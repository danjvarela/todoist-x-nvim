vim.api.nvim_create_user_command("Todoist", function()
  require("todoist").open()
end, { desc = "Open Todoist task manager" })
