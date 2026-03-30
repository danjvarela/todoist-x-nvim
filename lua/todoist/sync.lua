local M = {}
local parser = require("todoist.parser")
local api = require("todoist.api")
local ui = require("todoist.ui")

---Parses the buffer, diffs against cached state, and pushes all changes to
---Todoist in a single Sync API request. Resolves temp IDs in the cache after
---creation, then marks the buffer as unmodified.
---@param buf integer Buffer handle
M.save = function(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local current = parser.parse(lines, buf)
  local cached = vim.fn.json_decode(vim.b[buf].todoist_cache)

  local cached_by_id = {}
  for _, section in ipairs(cached) do
    for _, task in ipairs(section.tasks) do
      cached_by_id[task.id] = task
    end
  end

  local commands = {}

  for _, section in ipairs(current) do
    for _, task in ipairs(section.tasks) do
      if task.id:match("^tmp_") then
        table.insert(commands, {
          type = "item_add",
          temp_id = task.id,
          uuid = task.id,
          args = {
            content = task.content,
            parent_id = task.parent_id,
          },
        })
      else
        local cached_task = cached_by_id[task.id]
        if cached_task then
          if cached_task.content ~= task.content then
            table.insert(commands, {
              type = "item_update",
              uuid = vim.fn.tempname(),
              args = {
                id = task.id,
                content = task.content,
              },
            })
          end
          if cached_task.is_completed ~= task.is_completed then
            table.insert(commands, {
              type = task.is_completed and "item_complete" or "item_uncomplete",
              uuid = vim.fn.tempname(),
              args = { id = task.id },
            })
          end
          cached_by_id[task.id] = nil
        end
      end
    end
  end

  -- all remaining tasks in `cached_by_id` are for delete
  for id, _ in pairs(cached_by_id) do
    table.insert(commands, {
      type = "item_delete",
      uuid = vim.fn.tempname(),
      args = { id = id },
    })
  end

  if #commands > 0 then
    local result = api.sync_commands(commands)
    if not result then
      return
    end

    -- resolve temp IDs in the current sections to cache is accurate
    local mapping = result.temp_id_mapping or {}
    for _, section in ipairs(current) do
      for _, task in ipairs(section.tasks) do
        if mapping[task.id] then
          task.id = mapping[task.id]
        end
        if task.parent_id and mapping[task.parent_id] then
          task.parent_id = mapping[task.parent_id]
        end
      end
    end
  end

  vim.b[buf].todoist_cache = vim.fn.json_encode(current)
  vim.bo[buf].modified = false
end

---Fetches tasks for all configured sections, renders them into the buffer,
---and stores the initial cache for diffing on save.
---@param buf integer Buffer handle
M.load = function(buf)
  local config = require("todoist.config").get()
  local sections = vim.deepcopy(config.sections)

  for _, section in ipairs(sections) do
    ---@diagnostic disable-next-line
    section.tasks = api.get_tasks(section.filter) or {}
  end

  local lines = parser.render(sections, buf)
  ui.render_buffer(buf, lines)

  vim.b[buf].todoist_cache = vim.fn.json_encode(sections)
end

return M
