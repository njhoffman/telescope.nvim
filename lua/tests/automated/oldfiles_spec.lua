local finders = require "telescope.finders"
local internal = require "telescope.builtin.__internal"
local pickers = require "telescope.pickers"
local utils = require "telescope.utils"

describe("builtin.oldfiles", function()
  local old_new, old_table, old_iswin, bufnr, results

  before_each(function()
    old_new, old_table, old_iswin = pickers.new, finders.new_table, utils.iswin
    pickers.new = function()
      return { find = function() end }
    end
    finders.new_table = function(opts)
      results = opts.results
      return {}
    end
    bufnr = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(bufnr, "oil:///some/dir/")
    -- Oldfiles skips buffers that were never entered.
    local current = vim.api.nvim_get_current_buf()
    vim.api.nvim_set_current_buf(bufnr)
    vim.api.nvim_set_current_buf(current)
  end)

  after_each(function()
    pickers.new, finders.new_table, utils.iswin = old_new, old_table, old_iswin
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)

  it("keeps a session buffer with a protocol", function()
    internal.oldfiles {}
    assert.is_true(vim.tbl_contains(results, "oil:///some/dir/"))
  end)

  it("does not convert the slashes of a protocol path on Windows", function()
    utils.iswin = true
    internal.oldfiles {}
    assert.is_true(vim.tbl_contains(results, "oil:///some/dir/"))
  end)
end)
