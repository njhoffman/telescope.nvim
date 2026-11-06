local actions = require "telescope.actions"
local conf = require("telescope.config").values
local finders = require "telescope.finders"
local pickers = require "telescope.pickers"

describe("closing a picker", function()
  local old_loaded, old_preload

  local function open_picker()
    local picker = pickers.new({}, {
      prompt_title = "close spec",
      finder = finders.new_table { results = { "a", "b" } },
      sorter = conf.generic_sorter {},
    })
    picker:find()
    vim.wait(100)
    return picker
  end

  before_each(function()
    old_loaded = package.loaded.project_nvim
    old_preload = package.preload.project_nvim
    package.loaded.project_nvim = nil
  end)

  after_each(function()
    package.loaded.project_nvim = old_loaded
    package.preload.project_nvim = old_preload
  end)

  it("works without project.nvim", function()
    package.preload.project_nvim = function()
      error "module 'project_nvim' not found"
    end

    local picker = open_picker()
    local prompt_win = picker.prompt_win
    actions.close(picker.prompt_bufnr)

    assert.is_false(vim.api.nvim_win_is_valid(prompt_win))
    assert.is_true(picker.cache_picker.is_cached)
  end)
end)
