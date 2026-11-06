local actions = require "telescope.actions"
local conf = require("telescope.config").values
local finders = require "telescope.finders"
local pickers = require "telescope.pickers"
local previewers = require "telescope.previewers"
local themes = require "telescope.themes"

describe("themes.get_minimal", function()
  it("sets the theme and lets options override it", function()
    local opts = themes.get_minimal { sorting_strategy = "descending" }
    assert.are.equal("minimal", opts.theme)
    assert.are.equal("descending", opts.sorting_strategy)
    assert.are.equal("horizontal", opts.layout_strategy)
  end)

  it("limits the size to 80x15", function()
    local layout = themes.get_minimal().layout_config
    assert.are.equal(80, layout.width(nil, 200, 60))
    assert.are.equal(40, layout.width(nil, 40, 60))
    assert.are.equal(15, layout.height(nil, 200, 60))
    assert.are.equal(10, layout.height(nil, 200, 10))
  end)

  it("moves the joined border to the window on top", function()
    local top = themes.get_minimal().borderchars
    local bottom = themes.get_minimal({ layout_config = { prompt_position = "bottom" } }).borderchars
    assert.are.equal(top.prompt[5], bottom.results[5])
    assert.are.equal(top.results[5], bottom.prompt[5])
  end)

  it("uses its own borders for the vertical layout", function()
    local chars = themes.get_minimal({ layout_strategy = "vertical" }).borderchars
    assert.are.equal("╮", chars.prompt[6])
    assert.are.equal("╯", chars.preview[7])
  end)

  describe("layout", function()
    local old_lines, old_columns

    before_each(function()
      old_lines, old_columns = vim.o.lines, vim.o.columns
      vim.o.lines, vim.o.columns = 60, 200
    end)

    after_each(function()
      vim.o.lines, vim.o.columns = old_lines, old_columns
    end)

    local function open(prompt_position, strategy)
      local picker = pickers.new(
        themes.get_minimal {
          previewer = strategy == "vertical" and previewers.new_buffer_previewer { define_preview = function() end }
            or false,
          layout_strategy = strategy,
          layout_config = { prompt_position = prompt_position },
        },
        {
          prompt_title = "minimal spec",
          finder = finders.new_table { results = { "a", "b" } },
          sorter = conf.generic_sorter {},
        }
      )
      picker:find()
      vim.wait(100)
      local prompt = vim.api.nvim_win_get_config(picker.prompt_win)
      local results = vim.api.nvim_win_get_config(picker.results_win)
      local theme = picker.theme
      actions.close(picker.prompt_bufnr)
      return prompt, results, theme
    end

    it("reaches the picker, so the layout can apply it", function()
      local _, _, theme = open "bottom"
      assert.are.equal("minimal", theme)
    end)

    it("draws the lower window over the shared border", function()
      local prompt, results = open "bottom"
      assert.is_true(prompt.zindex > results.zindex)

      prompt, results = open "top"
      assert.is_true(results.zindex > prompt.zindex)
    end)

    it("shares borders and leaves room for results in the vertical layout", function()
      local prompt, results = open("bottom", "vertical")
      assert.is_true(prompt.zindex > results.zindex)
      assert.are.equal(results.row + results.height + 1, prompt.row)
      assert.is_true(results.height >= 5)

      prompt, results = open("top", "vertical")
      assert.is_true(results.zindex > prompt.zindex)
      assert.are.equal(prompt.row + prompt.height + 1, results.row)
      assert.is_true(results.height >= 5)
    end)

    it("respects an explicit mirror and height", function()
      local opts = themes.get_minimal {
        layout_strategy = "vertical",
        layout_config = {
          mirror = false,
          height = 20,
        },
      }
      assert.is_false(opts.layout_config.mirror)
      assert.are.equal(20, opts.layout_config.height)
    end)
  end)
end)
