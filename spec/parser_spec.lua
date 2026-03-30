local parser = require("todoist.parser")

-- render() uses shiftwidth which defaults to 0 in nlua, falling back to 2
local function make_sections(tasks)
  return {
    {
      title = "Today",
      filter = "today",
      tasks = tasks,
    },
  }
end

describe("parser.render", function()
  it("renders the section header with concealed filter", function()
    local lines = parser.render(make_sections({}))
    assert.are.equal("## Today ::today", lines[1])
  end)

  it("adds a blank line after each section", function()
    local lines = parser.render(make_sections({}))
    assert.are.equal("", lines[2])
  end)

  it("renders an uncompleted task with concealed id", function()
    local lines = parser.render(make_sections({
      { id = "1", content = "Buy milk", is_completed = false, parent_id = nil },
    }))
    assert.are.equal("- [ ] Buy milk ::1", lines[2])
  end)

  it("renders a completed task with x checkbox", function()
    local lines = parser.render(make_sections({
      { id = "1", content = "Send invoice", is_completed = true, parent_id = nil },
    }))
    assert.are.equal("- [x] Send invoice ::1", lines[2])
  end)

  it("indents subtasks by shiftwidth (2) per depth level", function()
    local lines = parser.render(make_sections({
      { id = "1", content = "Buy milk",   is_completed = false, parent_id = nil },
      { id = "2", content = "Organic",    is_completed = false, parent_id = "1" },
      { id = "3", content = "500ml size", is_completed = false, parent_id = "2" },
    }))
    assert.are.equal("- [ ] Buy milk ::1",       lines[2])
    assert.are.equal("  - [ ] Organic ::2",      lines[3])
    assert.are.equal("    - [ ] 500ml size ::3", lines[4])
  end)

  it("renders siblings at the same depth", function()
    local lines = parser.render(make_sections({
      { id = "1", content = "Buy milk",   is_completed = false, parent_id = nil },
      { id = "2", content = "Organic",    is_completed = false, parent_id = "1" },
      { id = "3", content = "Skimmed",    is_completed = false, parent_id = "1" },
    }))
    assert.are.equal("  - [ ] Organic ::2", lines[3])
    assert.are.equal("  - [ ] Skimmed ::3", lines[4])
  end)

  it("renders multiple sections", function()
    local sections = {
      { title = "Today", filter = "today", tasks = {
        { id = "1", content = "Task A", is_completed = false, parent_id = nil },
      }},
      { title = "Inbox", filter = "#Inbox", tasks = {
        { id = "2", content = "Task B", is_completed = false, parent_id = nil },
      }},
    }
    local lines = parser.render(sections)
    assert.are.equal("## Today ::today",   lines[1])
    assert.are.equal("- [ ] Task A ::1",   lines[2])
    assert.are.equal("",                   lines[3])
    assert.are.equal("## Inbox ::#Inbox",  lines[4])
    assert.are.equal("- [ ] Task B ::2",   lines[5])
    assert.are.equal("",                   lines[6])
  end)
end)

describe("parser.parse", function()
  it("parses a section header", function()
    local sections = parser.parse({ "## Today ::today" })
    assert.are.equal(1, #sections)
    assert.are.equal("Today", sections[1].title)
    assert.are.equal("today", sections[1].filter)
  end)

  it("parses an existing task with id", function()
    local sections = parser.parse({
      "## Today ::today",
      "- [ ] Buy milk ::123",
    })
    local task = sections[1].tasks[1]
    assert.are.equal("Buy milk", task.content)
    assert.are.equal("123", task.id)
    assert.is_false(task.is_completed)
    assert.is_nil(task.parent_id)
  end)

  it("parses a completed task", function()
    local sections = parser.parse({
      "## Today ::today",
      "- [x] Send invoice ::456",
    })
    assert.is_true(sections[1].tasks[1].is_completed)
  end)

  it("parses subtask parent_id from indentation", function()
    local sections = parser.parse({
      "## Today ::today",
      "- [ ] Buy milk ::1",
      "  - [ ] Organic ::2",
    })
    assert.is_nil(sections[1].tasks[1].parent_id)
    assert.are.equal("1", sections[1].tasks[2].parent_id)
  end)

  it("assigns a temp id to new tasks", function()
    local sections = parser.parse({
      "## Today ::today",
      "- [ ] Brand new task",
    })
    local id = sections[1].tasks[1].id
    assert.truthy(id:match("^tmp_"))
  end)

  it("does not assign temp id to existing tasks", function()
    local sections = parser.parse({
      "## Today ::today",
      "- [ ] Existing task ::999",
    })
    assert.are.equal("999", sections[1].tasks[1].id)
  end)

  it("ignores blank lines", function()
    local sections = parser.parse({
      "## Today ::today",
      "- [ ] Task A ::1",
      "",
      "- [ ] Task B ::2",
    })
    assert.are.equal(2, #sections[1].tasks)
  end)

  it("returns empty sections list for empty input", function()
    local sections = parser.parse({})
    assert.are.equal(0, #sections)
  end)

  it("round-trips through render and parse", function()
    local original = {
      {
        title = "Today",
        filter = "today",
        tasks = {
          { id = "1", content = "Buy milk",   is_completed = false, parent_id = nil },
          { id = "2", content = "Organic",    is_completed = false, parent_id = "1" },
          { id = "3", content = "Send invoice", is_completed = true, parent_id = nil },
        },
      },
    }
    local lines    = parser.render(original)
    local parsed   = parser.parse(lines)
    local tasks    = parsed[1].tasks

    assert.are.equal("1",           tasks[1].id)
    assert.are.equal("Buy milk",    tasks[1].content)
    assert.is_false(tasks[1].is_completed)
    assert.is_nil(tasks[1].parent_id)

    assert.are.equal("2",           tasks[2].id)
    assert.are.equal("Organic",     tasks[2].content)
    assert.are.equal("1",           tasks[2].parent_id)

    assert.are.equal("3",           tasks[3].id)
    assert.is_true(tasks[3].is_completed)
  end)
end)
