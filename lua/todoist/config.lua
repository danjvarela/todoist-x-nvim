local M = {}
local _config = {}

M.defaults = {
  api_token = nil, -- reads from vim.env.TODOIST_API_TOKEN if nil
  window = {
    type = "float", -- "float" | "split" | "vsplit"
    width = 0.8, -- for float: fraction of screen
    height = 0.8,
  },
  sections = {
    { title = "Today", filter = "today" },
    { title = "Inbox", filter = "#Inbox" },
  },
  conceallevel = 2,
}

M.merge = function(user_config)
  _config = vim.tbl_deep_extend("force", M.defaults, user_config or {})
end

M.get = function()
  return _config
end

return M
