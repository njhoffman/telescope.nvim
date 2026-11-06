local diagnostics = require("telescope.builtin.__diagnostics")
local pickers = require("telescope.pickers")

local severity = vim.diagnostic.severity

describe("builtin diagnostics filtering", function()
  local bufnr, ns, other_ns, old_pickers_new, previous_bufnr

  --- Runs the picker with `pickers.new` stubbed and returns the sorted messages it was given.
  local function messages(opts)
    local found = {}
    opts = vim.tbl_extend("force", { bufnr = 0 }, opts or {})
    opts.entry_maker = function(entry)
      table.insert(found, entry.text)
      return { value = entry, ordinal = entry.text, display = entry.text }
    end
    diagnostics.get(opts)
    table.sort(found)
    return found
  end

  before_each(function()
    old_pickers_new = pickers.new
    pickers.new = function()
      return { find = function() end }
    end
    previous_bufnr = vim.api.nvim_get_current_buf()
    ns = vim.api.nvim_create_namespace("telescope-test-filter")
    other_ns = vim.api.nvim_create_namespace("telescope-test-filter-other")
    bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(bufnr, vim.fn.tempname() .. ".py")
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "one", "two", "three" })
    vim.api.nvim_set_current_buf(bufnr)
    vim.diagnostic.set(ns, bufnr, {
      { lnum = 0, col = 0, severity = severity.ERROR, message = "error" },
      { lnum = 1, col = 0, severity = severity.WARN, message = "warn" },
      { lnum = 2, col = 0, severity = severity.HINT, message = "hint" },
    })
    vim.diagnostic.set(other_ns, bufnr, {
      { lnum = 0, col = 0, severity = severity.HINT, message = "other" },
    })
  end)

  after_each(function()
    pickers.new = old_pickers_new
    vim.diagnostic.reset(ns, bufnr)
    vim.diagnostic.reset(other_ns, bufnr)
    vim.api.nvim_set_current_buf(previous_bufnr)
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)

  it("returns everything without a filter", function()
    assert.are.same({ "error", "hint", "other", "warn" }, messages())
  end)

  it("honors an exact severity", function()
    assert.are.same({ "warn" }, messages({ severity = severity.WARN }))
  end)

  it("honors severity_limit as the lowest severity shown", function()
    assert.are.same({ "error", "warn" }, messages({ severity_limit = severity.WARN }))
  end)

  it("honors severity_bound as the highest severity shown", function()
    assert.are.same({ "hint", "other" }, messages({ severity_bound = severity.HINT }))
  end)

  it("honors namespace", function()
    assert.are.same({ "other" }, messages({ namespace = other_ns }))
  end)
end)
