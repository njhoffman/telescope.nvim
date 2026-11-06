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

  it("does not treat a name with an invalid scheme as a protocol", function()
    local other = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(other, "a_b://not/a/file")
    local current = vim.api.nvim_get_current_buf()
    vim.api.nvim_set_current_buf(other)
    vim.api.nvim_set_current_buf(current)
    internal.oldfiles {}
    vim.api.nvim_buf_delete(other, { force = true })
    assert.is_false(vim.tbl_contains(results, "a_b://not/a/file"))
  end)

  it("lists existing old files and drops missing ones", function()
    local real = vim.fn.tempname()
    vim.fn.writefile({ "x" }, real)
    local old_oldfiles = vim.v.oldfiles
    vim.v.oldfiles = { real, real .. ".missing" }
    internal.oldfiles { include_current_session = false }
    vim.v.oldfiles = old_oldfiles
    vim.fn.delete(real)
    assert.are.same({ real }, results)
  end)

  it("does not convert the slashes of a protocol path on Windows", function()
    utils.iswin = true
    internal.oldfiles {}
    assert.is_true(vim.tbl_contains(results, "oil:///some/dir/"))
  end)
end)
