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

  return { Authorization = "Bearer " .. token, ["Content-Type"] = "application/json" }
end

local _handle_response = function(res)
  if res.status >= 200 and res.status < 300 then
    return vim.json.decode(res.body)
  else
    vim.notify("Todoist API error: " .. res.status, vim.log.levels.ERROR)
  end
end

local _request = function(method, path, opts)
  local headers = _get_headers()
  if not headers then return nil end
  local res = curl[method](BASE_URL .. path, vim.tbl_extend("force", { headers = headers }, opts or {}))
  return _handle_response(res)
end

---@param filter string Todoist filter query string
---@return TodoistTask[]|nil
M.get_tasks = function(filter)
  return _request("get", "/tasks", { query = { filter = filter } })
end

---@param fields table Task fields: content (required), parent_id, project_id, description, due_string, priority, labels
---@return TodoistTask|nil
M.create_task = function(fields)
  return _request("post", "/tasks", { body = vim.fn.json_encode(fields) })
end

---@param id string Task ID
---@param fields table Fields to update: content, description, due_string, priority, labels
---@return TodoistTask|nil
M.update_task = function(id, fields)
  return _request("post", "/tasks/" .. id, { body = vim.fn.json_encode(fields) })
end

---@param id string Task ID
---@return nil
M.close_task = function(id)
  return _request("post", "/tasks/" .. id .. "/close")
end

---@param id string Task ID
---@return nil
M.reopen_task = function(id)
  return _request("post", "/tasks/" .. id .. "/reopen")
end

---@param id string Task ID
---@return nil
M.delete_task = function(id)
  return _request("delete", "/tasks/" .. id)
end

return M
