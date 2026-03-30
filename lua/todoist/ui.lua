local M = {}

M.open = function()
  local config = require("todoist.config").get()
  local window_config = config.window
  local buf = vim.api.nvim_create_buf(false, true)
  local win

  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].buftype = "acwrite"
  vim.api.nvim_buf_set_name(buf, "Todoist")

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
    vim.cmd([[
      syn match TodoistConceal / ::\S\+/ conceal containedin=ALL
    ]])
  end)

  return {
    buf = buf,
    win = win,
  }
end

M.render_buffer = function(buf, lines)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modified = false
end

return M
