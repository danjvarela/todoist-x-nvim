local M = {}

---@param buf integer|nil
---@return integer
local _get_indent_size = function(buf)
  return (buf and vim.bo[buf].shiftwidth) or vim.bo.shiftwidth or 2
end

---@return string
local _generate_temp_id = function()
  return "tmp_" .. vim.fn.tempname()
end

local _header_match = function(line)
  local title, filter = line:match("^##+ (.+) ::(.+)$")
  if title then
    return { title = title, filter = filter }
  end
end

local _existing_task_match = function(line)
  local indent, checkbox, content, id = line:match("^(%s*)- %[([%sx])%] (.+) ::(%S+)$")
  if id then
    return { indent = indent, checkbox = checkbox, content = content, id = id }
  else
    return nil
  end
end

local _new_task_match = function(line)
  local indent, checkbox, content = line:match("^(%s*)- %[([%sx])%] (.+)$")
  if content and not content:match(" ::%S+$") then
    return { indent = indent, checkbox = checkbox, content = content, id = _generate_temp_id() }
  else
    return nil
  end
end

---@class TodoistTask
---@field id string Todoist task ID
---@field content string Task text
---@field is_completed boolean Whether the task is completed
---@field parent_id string|nil ID of the parent task, or nil if root-level

---@class TodoistSectionWithTasks
---@field title string Display name shown in the buffer heading
---@field filter string Todoist filter query string
---@field tasks TodoistTask[] Flat list of tasks (including subtasks) for this section

---Renders sections with their tasks into a list of buffer lines.
---Each task line embeds its ID as a concealed suffix (e.g. `- [ ] Buy milk ::123`).
---Subtasks are indented by `shiftwidth` spaces per depth level.
---@param sections TodoistSectionWithTasks[]
---@param buf integer|nil Buffer handle to read shiftwidth from. Falls back to current buffer.
---@return string[] lines
M.render = function(sections, buf)
  local lines = {}
  local indent_size = _get_indent_size(buf)

  for _, section in ipairs(sections) do
    local parent_tasks, children_of = {}, {}

    table.insert(lines, "## " .. section.title .. " ::" .. section.filter)

    for _, task in ipairs(section.tasks) do
      if task.parent_id == nil then
        table.insert(parent_tasks, task)
      else
        children_of[task.parent_id] = children_of[task.parent_id] or {}
        table.insert(children_of[task.parent_id], task)
      end
    end

    local function walk(task, depth)
      local checkbox = task.is_completed and "x" or " "
      local indent = string.rep(" ", depth * indent_size)
      table.insert(lines, indent .. "- [" .. checkbox .. "] " .. task.content .. " ::" .. task.id)

      for _, child in ipairs(children_of[task.id] or {}) do
        walk(child, depth + 1)
      end
    end

    for _, parent_task in ipairs(parent_tasks) do
      walk(parent_task, 0)
    end

    table.insert(lines, "")
  end

  return lines
end

---Parses buffer lines back into sections with tasks.
---Tasks with a `::id` suffix are treated as existing tasks.
---Tasks without an ID are assigned a temporary ID (`tmp_*`) and treated as new.
---Nesting is inferred from indentation depth relative to `shiftwidth`.
---@param lines string[]
---@param buf integer|nil Buffer handle to read shiftwidth from. Falls back to current buffer.
---@return TodoistSectionWithTasks[]
M.parse = function(lines, buf)
  local sections = {}
  local current_section
  local indent_size = _get_indent_size(buf)

  local depth_stack = {}

  for _, line in ipairs(lines) do
    local header, existing_task, new_task = _header_match(line), _existing_task_match(line), _new_task_match(line)
    if header then
      if current_section ~= nil then
        table.insert(sections, current_section)
      end
      current_section = { title = header.title, filter = header.filter, tasks = {} }
    elseif existing_task or new_task then
      local task = existing_task or new_task
      assert(task ~= nil, "task must not be nil here")
      local depth = math.floor(#task.indent / indent_size)
      local parent_id = depth_stack[depth - 1]
      table.insert(current_section.tasks, {
        id = task.id,
        content = task.content,
        is_completed = task.checkbox == "x",
        parent_id = parent_id,
      })
      depth_stack[depth] = task.id
    end
  end

  if current_section ~= nil then
    table.insert(sections, current_section)
  end

  return sections
end

return M
