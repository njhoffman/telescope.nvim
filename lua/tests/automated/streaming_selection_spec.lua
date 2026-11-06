local actions = require "telescope.actions"
local async = require "plenary.async"
local conf = require("telescope.config").values
local pickers = require "telescope.pickers"

describe("selection while results stream", function()
  --- A finder that adds entries over time, and finishes only when told to.
  local function streaming_finder(values, delay)
    local finish = false
    local finder = setmetatable({
      close = function() end,
      finish = function()
        finish = true
      end,
    }, {
      __call = function(_, _, process_result, process_complete)
        for _, value in ipairs(values) do
          async.util.sleep(delay)
          process_result { value = value, ordinal = value, display = value }
        end
        while not finish do
          async.util.sleep(20)
        end
        process_complete()
      end,
    })
    return finder
  end

  local function open(finder, opts)
    local picker = pickers.new(opts or {}, {
      prompt_title = "streaming spec",
      finder = finder,
      sorter = conf.generic_sorter {},
    })
    picker:find()
    return picker
  end

  it("selects a result before the finder finishes", function()
    local finder = streaming_finder({ "alpha", "beta" }, 20)
    local picker = open(finder)
    vim.wait(400, function()
      return picker._selection_entry ~= nil
    end)

    assert.is_not_nil(picker._selection_entry)
    assert.is_truthy(vim.tbl_contains({ "alpha", "beta" }, picker._selection_entry.value))
    finder.finish()
    vim.wait(100)
    actions.close(picker.prompt_bufnr)
  end)

  it("keeps a selection the user moved while results stream", function()
    local values = {}
    for i = 1, 30 do
      values[i] = "entry" .. i
    end
    local finder = streaming_finder(values, 20)
    local picker = open(finder, { sorting_strategy = "ascending" })
    vim.wait(400, function()
      return picker.manager and picker.manager:num_results() >= 5 and picker._selection_entry ~= nil
    end)

    local start = picker:get_selection_row()
    actions.move_selection_next(picker.prompt_bufnr)
    local moved = picker:get_selection_row()
    assert.are_not.equal(start, moved)
    vim.wait(300)

    assert.are.equal(moved, picker:get_selection_row())
    finder.finish()
    vim.wait(100)
    actions.close(picker.prompt_bufnr)
  end)

  it("accepts the original arguments of get_result_processor", function()
    local finder = streaming_finder({}, 1)
    local picker = open(finder)
    vim.wait(50)
    local process = picker:get_result_processor(picker._find_id, "", function() end)
    assert.has_no.errors(function()
      process { value = "x", ordinal = "x", display = "x" }
    end)
    finder.finish()
    vim.wait(100)
    actions.close(picker.prompt_bufnr)
  end)
end)
