local action_set = require "telescope.actions.set"
local actions = require "telescope.actions"
local conf = require("telescope.config").values
local finders = require "telescope.finders"
local pickers = require "telescope.pickers"
local previewers = require "telescope.previewers"

describe("preview scrolling", function()
  local old_lines, old_columns, picker

  local function topline()
    return vim.fn.getwininfo(picker.layout.preview.winid)[1].topline
  end

  before_each(function()
    old_lines, old_columns = vim.o.lines, vim.o.columns
    vim.o.lines, vim.o.columns = 60, 200
    picker = pickers.new({}, {
      prompt_title = "scroll spec",
      finder = finders.new_table { results = { "a", "b" } },
      sorter = conf.generic_sorter {},
      previewer = previewers.new_buffer_previewer {
        define_preview = function(self)
          local lines = {}
          for i = 1, 500 do
            lines[i] = tostring(i)
          end
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
        end,
      },
    })
    picker:find()
    vim.wait(150)
  end)

  after_each(function()
    actions.close(picker.prompt_bufnr)
    vim.o.lines, vim.o.columns = old_lines, old_columns
  end)

  it("moves by an exact number of lines", function()
    local start = topline()
    action_set.scroll_previewer_by(picker.prompt_bufnr, 7)
    assert.are.equal(start + 7, topline())
    action_set.scroll_previewer_by(picker.prompt_bufnr, -3)
    assert.are.equal(start + 4, topline())
  end)

  it("ignores a zero line scroll", function()
    local start = topline()
    action_set.scroll_previewer_by(picker.prompt_bufnr, 0)
    assert.are.equal(start, topline())
  end)

  it("moves by a window height for a page", function()
    local start = topline()
    local height = vim.api.nvim_win_get_height(picker.layout.preview.winid)
    action_set.scroll_previewer_page(picker.prompt_bufnr, 1)
    assert.are.equal(start + height, topline())
    action_set.scroll_previewer_page(picker.prompt_bufnr, -1)
    assert.are.equal(start, topline())
  end)

  it("is reachable through the line and page actions", function()
    local start = topline()
    actions.preview_scrolling_down_line(picker.prompt_bufnr)
    assert.are.equal(start + 1, topline())
    actions.preview_scrolling_up_line(picker.prompt_bufnr)
    assert.are.equal(start, topline())
    actions.preview_scrolling_page_down(picker.prompt_bufnr)
    assert.is_true(topline() > start)
  end)
end)

describe("preview scrolling without a preview", function()
  it("does nothing", function()
    local picker = pickers.new({ previewer = false }, {
      prompt_title = "scroll spec",
      finder = finders.new_table { results = { "a" } },
      sorter = conf.generic_sorter {},
    })
    picker:find()
    vim.wait(100)
    assert.has_no.errors(function()
      action_set.scroll_previewer_by(picker.prompt_bufnr, 1)
      action_set.scroll_previewer_page(picker.prompt_bufnr, 1)
    end)
    actions.close(picker.prompt_bufnr)
  end)
end)
