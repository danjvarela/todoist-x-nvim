local M = {}
local curl = require("plenary.curl")
local config = require("todoist.config")
local BASE_URL = "https://api.todoist.com/api/v1"

local _get_token = function()
  return config.get().api_token or vim.env.TODOIST_API_TOKEN
end

local _get_headers = function()
  local token = _get_token()

  if not token then
    vim.notify(
      "todoist-x-nvim: no API token set. Set api_token in setup() or TODOIST_API_TOKEN env var.",
      vim.log.levels.ERROR
    )
    return nil
  end

  return { Authorization = "Bearer " .. token }
end

local _handle_response = function(res)
  if res.status >= 200 and res.status < 300 then
    return vim.json.decode(res.body)
  else
    vim.notify("Todoist API error: " .. res.status, vim.log.levels.ERROR)
  end
end

---Fetches tasks matching a Todoist filter query.
---@param filter string Todoist filter query string (e.g. "today", "#Inbox")
---@return TodoistTask[]|nil
M.get_tasks = function(filter)
  local headers = _get_headers()
  if not headers then
    return nil
  end
  local res = curl.get(BASE_URL .. "/tasks", {
    headers = headers,
    query = { filter = filter },
  })
  local data = _handle_response(res)
  if not data then
    return nil
  end

  local tasks = {}
  for _, t in ipairs(data.results or {}) do
    table.insert(tasks, {
      id = t.id,
      content = t.content,
      is_completed = t.checked == true,
      parent_id = t.parent_id ~= vim.NIL and t.parent_id or nil,
    })
  end
  return tasks
end

---@class TodoistSyncCommand
---@field type string Command type (e.g. "item_add", "item_update", "item_delete", "item_complete", "item_uncomplete")
---@field uuid string Unique command ID for idempotency and result mapping
---@field temp_id string|nil Temporary ID for new resources, so they can be referenced in the same batch
---@field args table Command arguments (varies by type)

---Sends a batch of Sync API commands in a single request.
---Returns the full sync response including `sync_status` and `temp_id_mapping`.
---@param commands TodoistSyncCommand[]
---@return table|nil
M.sync_commands = function(commands)
  local headers = _get_headers()
  if not headers then
    return nil
  end
  local res = curl.post(BASE_URL .. "/sync", {
    headers = headers,
    body = { commands = vim.fn.json_encode(commands) },
  })
  return _handle_response(res)
end

return M
