local action_state = require "telescope.actions.state"
local actions = require "telescope.actions"
local builtin = require "telescope.builtin"
local conf = require("telescope.config").values
local finders = require "telescope.finders"
local pickers = require "telescope.pickers"
local previewers = require "telescope.previewers"

describe("resuming a picker", function()
  local function open(opts)
    local picker = pickers.new(opts, {
      prompt_title = "resume spec",
      finder = finders.new_table { results = { "a", "b" } },
      sorter = conf.generic_sorter {},
      previewer = previewers.new_buffer_previewer { define_preview = function() end },
    })
    picker:find()
    vim.wait(100)
    return picker
  end

  local function resume(opts)
    builtin.resume(opts or {})
    vim.wait(100)
    return action_state.get_current_picker(vim.api.nvim_get_current_buf())
  end

  it("keeps the extension export name on the picker", function()
    local picker = open { __name = "ext.export" }
    assert.are.equal("ext.export", picker.__name)
    actions.close(picker.prompt_bufnr)
  end)

  it("keeps a per-picker preview.debounce", function()
    actions.close(open({ preview = { debounce = 20 } }).prompt_bufnr)
    local resumed = resume()
    assert.are.equal(20, resumed.preview_debounce)
    assert.is_not_nil(resumed._preview_refresh_debounced)
    actions.close(resumed.prompt_bufnr)
  end)

  it("lets resume options override it", function()
    actions.close(open({ preview = { debounce = 20 } }).prompt_bufnr)
    local resumed = resume { preview = { debounce = 50 } }
    assert.are.equal(50, resumed.preview_debounce)
    actions.close(resumed.prompt_bufnr)
  end)
end)
