local action_set = require "telescope.actions.set"
local actions = require "telescope.actions"
local conf = require("telescope.config").values
local finders = require "telescope.finders"
local pickers = require "telescope.pickers"
local previewers = require "telescope.previewers"

local function open_timers()
  local count = 0
  vim.uv.walk(function(handle)
    if handle:get_type() == "timer" and not handle:is_closing() then
      count = count + 1
    end
  end)
  return count
end

local function open_picker()
  local picker = pickers.new({ preview = { debounce = 10 } }, {
    prompt_title = "timers spec",
    finder = finders.new_table { results = { "a", "b" } },
    sorter = conf.generic_sorter {},
    previewer = previewers.new_buffer_previewer {
      define_preview = function(self)
        local lines = {}
        for i = 1, 200 do
          lines[i] = tostring(i)
        end
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
      end,
    },
  })
  picker:find()
  vim.wait(100)
  return picker
end

local function close_picker(picker)
  actions.close(picker.prompt_bufnr)
  vim.wait(50)
end

describe("picker timers", function()
  local old_lines, old_columns

  before_each(function()
    old_lines, old_columns = vim.o.lines, vim.o.columns
    vim.o.lines, vim.o.columns = 60, 200
    -- First open loads modules that keep their own timers.
    close_picker(open_picker())
  end)

  after_each(function()
    vim.o.lines, vim.o.columns = old_lines, old_columns
  end)

  it("are closed when the picker closes", function()
    local baseline = open_timers()
    for _ = 1, 3 do
      close_picker(open_picker())
    end
    assert.are.equal(baseline, open_timers())
  end)

  it("reuse one timer for repeated smooth scrolling", function()
    local baseline = open_timers()
    local picker = open_picker()
    local opened = open_timers()

    for _ = 1, 5 do
      action_set.smoothscroll_previewer_by(picker.prompt_bufnr, 20)
      vim.wait(5)
    end
    vim.wait(200)
    assert.is_true(open_timers() <= opened + 1)

    close_picker(picker)
    assert.are.equal(baseline, open_timers())
  end)

  it("smooth scrolling still moves the preview", function()
    local picker = open_picker()
    local winid = picker.layout.preview.winid
    action_set.smoothscroll_previewer_by(picker.prompt_bufnr, 20)
    vim.wait(300)
    assert.is_true(vim.fn.getwininfo(winid)[1].topline > 1)
    close_picker(picker)
  end)

  it("tolerate use and detach after closing", function()
    local picker = open_picker()
    close_picker(picker)
    assert.has_no.errors(function()
      picker._preview_refresh_debounced()
      picker:_detach()
    end)
  end)
end)
