local M = {}

---Find an existing buffer named "Todoist", or nil.
---@return integer|nil
local function _find_buf()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_name(buf):match("Todoist$") then
      return buf
    end
  end
end

---Find a window displaying the given buffer, or nil.
---@param buf integer
---@return integer|nil
local function _find_win(buf)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == buf then
      return win
    end
  end
end

M.open = function()
  local config = require("todoist.config").get()
  local window_config = config.window

  -- Reuse existing buffer if present
  local buf = _find_buf()
  if buf then
    local existing_win = _find_win(buf)
    if existing_win then
      -- Already visible: just focus it
      vim.api.nvim_set_current_win(existing_win)
      return { buf = buf, win = existing_win }
    end
  else
    buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].filetype = "markdown"
    vim.bo[buf].buftype = "acwrite"
    vim.api.nvim_buf_set_name(buf, "Todoist")
  end

  local win
  if window_config.type == "float" then
    local width = math.floor(vim.o.columns * window_config.width)
    local height = math.floor(vim.o.lines * window_config.height)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)
    win = vim.api.nvim_open_win(buf, true, {
      relative = "editor",
      style = "minimal",
      border = "rounded",
      width = width,
      height = height,
      row = row,
      col = col,
    })
  elseif window_config.type == "split" then
    vim.cmd(window_config.height and (window_config.height .. "split") or "split")
    win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, buf)
  else
    vim.cmd(window_config.width and (window_config.width .. "vsplit") or "vsplit")
    win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, buf)
  end

  vim.wo[win].conceallevel = config.conceallevel
  vim.wo[win].concealcursor = "nc"

  vim.api.nvim_buf_call(buf, function()
    vim.cmd([[syn match TodoistConceal / ::.*/ conceal containedin=ALL]])
  end)

  return { buf = buf, win = win }
end

M.render_buffer = function(buf, lines)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modified = false
end

return M
