local actions = require "telescope.actions"
local conf = require("telescope.config").values
local finders = require "telescope.finders"
local pickers = require "telescope.pickers"
local previewers = require "telescope.previewers"

describe("preview.debounce", function()
  local function open(debounce)
    local picker = pickers.new({ preview = { debounce = debounce } }, {
      prompt_title = "debounce spec",
      finder = finders.new_table { results = { "a", "b", "c" } },
      sorter = conf.generic_sorter {},
      previewer = previewers.new_buffer_previewer { define_preview = function() end },
    })
    picker:find()
    vim.wait(100)
    local refreshes = 0
    local refresh = picker.refresh_previewer
    picker.refresh_previewer = function(self)
      refreshes = refreshes + 1
      return refresh(self)
    end
    return picker, function()
      return refreshes
    end
  end

  it("coalesces rapid refreshes into one trailing call", function()
    local picker, refreshes = open(30)
    for _ = 1, 10 do
      picker:_schedule_preview_refresh()
    end
    assert.are.equal(0, refreshes())
    vim.wait(200, function()
      return refreshes() > 0
    end)
    vim.wait(60)
    assert.are.equal(1, refreshes())
    actions.close(picker.prompt_bufnr)
  end)

  it("refreshes immediately when disabled", function()
    local picker, refreshes = open(0)
    for _ = 1, 3 do
      picker:_schedule_preview_refresh()
    end
    assert.are.equal(3, refreshes())
    actions.close(picker.prompt_bufnr)
  end)

  it("does not refresh after the picker closes", function()
    local picker, refreshes = open(30)
    picker:_schedule_preview_refresh()
    actions.close(picker.prompt_bufnr)
    vim.wait(100)
    assert.are.equal(0, refreshes())
  end)
end)
