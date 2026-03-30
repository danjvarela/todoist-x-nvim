local M = {}

M.setup = function(opts)
  require("todoist.config").merge(opts)
end

M.open = function()
  local ui = require("todoist.ui")
  local sync = require("todoist.sync")

  local result = ui.open()
  sync.load(result.buf)
end

vim.api.nvim_create_autocmd("BufWriteCmd", {
  pattern = "Todoist",
  callback = function(ev)
    require("todoist.sync").save(ev.buf)
  end,
})

return M
