local M = {}
local _config = {}

---@class TodoistWindowConfig
---@field type "float"|"split"|"vsplit" Window style
---@field width number For "float": fraction of screen width (0-1). For "vsplit": number of columns.
---@field height number For "float": fraction of screen height (0-1). For "split": number of rows.

---@class TodoistSection
---@field title string Display name shown in the buffer heading
---@field filter string Todoist filter query string (e.g. "today", "#Inbox")

---@class TodoistConfig
---@field api_token string|nil API token. Falls back to vim.env.TODOIST_API_TOKEN if nil
---@field window TodoistWindowConfig Window appearance and layout
---@field sections TodoistSection[] Sections to display, each with a title and filter
---@field conceallevel number Neovim conceallevel for the todoist buffer (0-3)

---@type TodoistConfig
M.defaults = {
  api_token = nil,
  window = {
    type = "float",
    width = 0.8,
    height = 0.8,
  },
  sections = {
    { title = "Today", filter = "today" },
    { title = "Inbox", filter = "#Inbox" },
  },
  conceallevel = 2,
}

---Merges user-provided config over the defaults and stores the result.
---@param user_config TodoistConfig|nil
M.merge = function(user_config)
  _config = vim.tbl_deep_extend("force", M.defaults, user_config or {})
end

---Returns the active merged config. Falls back to defaults if setup() was never called.
---@return TodoistConfig
M.get = function()
  if vim.tbl_isempty(_config) then
    return M.defaults
  end
  return _config
end

return M
