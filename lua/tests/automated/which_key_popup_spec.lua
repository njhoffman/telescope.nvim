local actions = require "telescope.actions"
local conf = require("telescope.config").values
local finders = require "telescope.finders"
local pickers = require "telescope.pickers"

describe("actions.which_key popup", function()
  local picker, old_lines, old_columns

  before_each(function()
    -- Large enough to render every default mapping.
    old_lines, old_columns = vim.o.lines, vim.o.columns
    vim.o.lines, vim.o.columns = 60, 200
    picker = pickers.new({}, {
      prompt_title = "which_key popup spec",
      finder = finders.new_table { results = { "a", "b" } },
      sorter = conf.generic_sorter {},
    })
    picker:find()
    vim.wait(100)
  end)

  after_each(function()
    actions.close(picker.prompt_bufnr)
    vim.o.lines, vim.o.columns = old_lines, old_columns
  end)

  local function popup_bufs()
    return vim.tbl_filter(function(buf)
      return vim.api.nvim_buf_get_name(buf):find("_TelescopeWhichKey", 1, true) ~= nil
    end, vim.api.nvim_list_bufs())
  end

  it("links its highlight groups to groups that exist", function()
    actions.which_key(picker.prompt_bufnr)
    local prefix = "TelescopeWhichKey"
    local checked = 0
    for name in pairs(vim.api.nvim_get_hl(0, {})) do
      if name:sub(1, #prefix) == prefix then
        local link = vim.api.nvim_get_hl(0, { name = name }).link
        local target = vim.api.nvim_get_hl(0, { name = name, link = false })
        assert.is_false(vim.tbl_isempty(target), name .. " links to an undefined group: " .. tostring(link))
        checked = checked + 1
      end
    end
    assert.is_true(checked >= 11)
    actions.which_key(picker.prompt_bufnr)
  end)

  it("shows the mappings that fit on a small screen", function()
    vim.o.lines, vim.o.columns = 24, 80
    actions.which_key(picker.prompt_bufnr)

    local popup = vim.fn.bufnr "_TelescopeWhichKey"
    local lines = vim.api.nvim_buf_get_lines(popup, 0, -1, false)
    local text = table.concat(lines, "\n")
    assert.is_truthy(text:find(" -> ", 1, true))
    assert.is_truthy(text:find("more", 1, true))

    actions.which_key(picker.prompt_bufnr)
  end)

  it("opens with highlighted mappings and toggles closed", function()
    actions.which_key(picker.prompt_bufnr)

    local bufs = popup_bufs()
    assert.is_true(#bufs > 0)
    local ns = vim.api.nvim_create_namespace "telescope_whichkey"
    local highlighted = 0
    for _, buf in ipairs(bufs) do
      highlighted = highlighted + #vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, {})
    end
    assert.is_true(highlighted > 0)

    actions.which_key(picker.prompt_bufnr)
    assert.are.same({}, popup_bufs())
  end)
end)
