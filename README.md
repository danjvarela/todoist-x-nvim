# todoist-x-nvim

A Neovim plugin that integrates with [Todoist](https://todoist.com). Open your tasks in a markdown buffer, edit them naturally, and save to sync changes back to Todoist.

## Requirements

- Neovim 0.11+
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- A [Todoist API token](https://app.todoist.com/app/settings/integrations/developer)

## Installation

### lazy.nvim

```lua
{
  "your-username/todoist-x-nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {
    -- see Configuration below
  },
}
```

## Configuration

Pass options to `setup()` (or via `opts` in lazy.nvim). All fields are optional.

```lua
require("todoist").setup({
  -- API token. Falls back to vim.env.TODOIST_API_TOKEN if not set here.
  api_token = nil,

  window = {
    type = "float",  -- "float" | "split" | "vsplit"
    width = 0.8,     -- float: fraction of screen width; vsplit: number of columns
    height = 0.8,    -- float: fraction of screen height; split: number of rows
  },

  -- Each section maps a heading to a Todoist filter query.
  -- See: https://todoist.com/help/articles/introduction-to-filters
  sections = {
    { title = "Today", filter = "today" },
    { title = "Inbox", filter = "#Inbox" },
  },

  conceallevel = 2,  -- conceals the ::filter and ::id markers in the buffer
})
```

### API token

Set the `TODOIST_API_TOKEN` environment variable or pass `api_token` to `setup()`.

```bash
export TODOIST_API_TOKEN="your_token_here"
```

## Usage

Run `:Todoist` to open the task buffer. Neovim fetches your tasks and renders them as a markdown checklist.

### Buffer format

```markdown
## Today ::today

- [ ] Buy milk ::2abc123
  - [ ] Skimmed ::3def456
- [x] Read emails ::4ghi789

## Inbox ::#Inbox

- [ ] New task idea ::5jkl012
```

- `## Heading ::filter` — section header; the `::filter` part is concealed
- `- [ ] task ::id` — incomplete task; the `::id` part is concealed
- `- [x] task ::id` — completed task
- Subtasks are indented by `shiftwidth` spaces per level

### Editing

Edit the buffer like any markdown file:

| Action | How |
|---|---|
| Complete a task | Change `[ ]` to `[x]` |
| Uncomplete a task | Change `[x]` to `[ ]` |
| Add a new task | Add a new `- [ ] task` line (no `::id` needed) |
| Delete a task | Delete the line |
| Rename a task | Edit the text |

### Saving

Write the buffer (`:w`) to sync all changes to Todoist in a single batched request.

## Development

### Run tests

Requires Neovim 0.11+ (uses `vim.pack.add` to bootstrap [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) automatically).

```bash
make test
```
