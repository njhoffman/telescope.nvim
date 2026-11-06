local actions = require "telescope.actions"
local conf = require("telescope.config").values
local finders = require "telescope.finders"
local pickers = require "telescope.pickers"
local previewers = require "telescope.previewers"

describe("center layout results_height", function()
  local old_lines, old_columns

  before_each(function()
    old_lines, old_columns = vim.o.lines, vim.o.columns
    vim.o.lines, vim.o.columns = 60, 200
  end)

  after_each(function()
    vim.o.lines, vim.o.columns = old_lines, old_columns
  end)

  local function geometry(results_height)
    local picker = pickers.new({
      layout_strategy = "center",
      layout_config = { results_height = results_height, height = 0.8, preview_cutoff = 1 },
    }, {
      prompt_title = "results_height spec",
      finder = finders.new_table { results = { "a" } },
      sorter = conf.generic_sorter {},
      previewer = previewers.new_buffer_previewer { define_preview = function() end },
    })
    picker:find()
    vim.wait(80)
    local config = function(win)
      return win and vim.api.nvim_win_get_config(win) or nil
    end
    local prompt, results, preview = config(picker.prompt_win), config(picker.results_win), config(picker.preview_win)
    actions.close(picker.prompt_bufnr)
    vim.wait(30)
    return prompt, results, preview
  end

  it("sets the results height and gives the rest to the preview", function()
    local prompt, results, preview = geometry(5)
    assert.are.equal(5, results.height)
    assert.is_true(preview.height > 5)
    assert.is_true(prompt.row > preview.row)
    assert.is_true(results.row > prompt.row)
  end)

  it("stays on screen when asked for more room than there is", function()
    local prompt, results = geometry(100)
    assert.is_true(prompt.row >= 0)
    assert.is_true(results.row >= 0)
    assert.is_true(results.row + results.height <= vim.o.lines)
  end)
end)
