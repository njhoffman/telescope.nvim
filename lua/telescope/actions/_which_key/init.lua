-- Which-key popup for telescope pickers.
--
-- Rewritten from the monolithic actions.which_key. Adds:
--   * mapping categorization (default / user_global / picker) with per-
--     category highlights, surfaced via the origin tag set in
--     lua/telescope/mappings.lua
--   * priority-based truncation on overflow (drops `default` first, then
--     `user_global`, always keeps `picker`)
--   * VimResized handling (close and re-run with the same opts)
--   * key-code substitution via `key_labels` (exact) + `replace_keys`
--     (Lua patterns)

local api = vim.api
local popup = require("plenary.popup")

local action_state = require("telescope.actions.state")
local config = require("telescope.config")
local utils = require("telescope.utils")

local display_mod = require("telescope.actions._which_key.display")
local hl_mod = require("telescope.actions._which_key.highlights")
local layout_mod = require("telescope.actions._which_key.layout")
local mappings_mod = require("telescope.actions._which_key.mappings")

local M = {}

M.WIN_BUFNAME = "_TelescopeWhichKey"
M.BORDER_BUFNAME = "_TelescopeWhichKeyBorder"

local function resolve_opts(opts)
  opts = opts or {}
  opts.max_height = vim.F.if_nil(opts.max_height, 0.4)
  opts.only_show_current_mode = vim.F.if_nil(opts.only_show_current_mode, true)
  opts.mode_width = vim.F.if_nil(opts.mode_width, 1)
  opts.keybind_width = vim.F.if_nil(opts.keybind_width, 7)
  opts.name_width = vim.F.if_nil(opts.name_width, 30)
  opts.line_padding = vim.F.if_nil(opts.line_padding, 1)
  opts.separator = vim.F.if_nil(opts.separator, " -> ")
  opts.close_with_action = vim.F.if_nil(opts.close_with_action, true)
  opts.normal_hl = vim.F.if_nil(opts.normal_hl, "TelescopeWhichKeyNormal")
  opts.border_hl = vim.F.if_nil(opts.border_hl, "TelescopeWhichKeyBorder")
  opts.winblend = vim.F.if_nil(opts.winblend, config.values.winblend)
  if type(opts.winblend) == "function" then
    opts.winblend = opts.winblend()
  end
  opts.zindex = vim.F.if_nil(opts.zindex, 100)
  opts.column_padding = vim.F.if_nil(opts.column_padding, "  ")
  opts.column_indent = vim.F.if_nil(opts.column_indent, 4)
  opts.resize = vim.F.if_nil(opts.resize, true)
  opts.categorize_mappings = vim.F.if_nil(opts.categorize_mappings, true)
  opts.category_drop_order = vim.F.if_nil(opts.category_drop_order, { "default", "user_global" })
  opts.use_default_key_labels = vim.F.if_nil(opts.use_default_key_labels, false)
  return opts
end

--- Detect and close an already-open which-key popup. Returns true if a
--- popup was present (caller should treat this as a toggle-off).
local function toggle_close()
  local km_bufs = {}
  for _, buf in ipairs(api.nvim_list_bufs()) do
    for _, bufname in ipairs { M.WIN_BUFNAME, M.BORDER_BUFNAME } do
      if string.find(api.nvim_buf_get_name(buf), bufname) then
        table.insert(km_bufs, buf)
      end
    end
  end
  if vim.tbl_isempty(km_bufs) then
    return false
  end
  for _, buf in ipairs(km_bufs) do
    utils.buf_delete(buf)
    for _, win_id in ipairs(vim.fn.win_findbuf(buf)) do
      pcall(api.nvim_win_close, win_id, true)
    end
  end
  return true
end

--- Compute popup placement relative to the picker layout. Matches the
--- original positioning heuristic so UX is unchanged.
local function compute_placement(picker)
  local win_central_row = function(win_nr)
    return api.nvim_win_get_position(win_nr)[1] + 0.5 * api.nvim_win_get_height(win_nr)
  end
  local prompt_row = win_central_row(picker.prompt_win)
  local results_row = win_central_row(picker.results_win)
  local preview_row = picker.preview_win and win_central_row(picker.preview_win) or results_row
  return prompt_row < 0.4 * vim.o.lines
    or (prompt_row < 0.6 * vim.o.lines and results_row + preview_row < vim.o.lines)
end

local function register_close_hooks(state, opts, prompt_bufnr)
  -- Close on the target buffer being left (prompt closes / picker exits).
  api.nvim_create_autocmd("BufLeave", {
    buffer = state.km_buf,
    once = true,
    callback = function()
      M.close(state)
    end,
  })

  -- Either TelescopeKeymap (close_with_action) or BufWinLeave of the prompt.
  local close_event, close_pattern, close_buffer
  if opts.close_with_action then
    close_event, close_pattern, close_buffer = "User", "TelescopeKeymap", nil
  else
    close_event, close_pattern, close_buffer = "BufWinLeave", nil, prompt_bufnr
  end
  vim.schedule(function()
    api.nvim_create_autocmd(close_event, {
      pattern = close_pattern,
      buffer = close_buffer,
      once = true,
      callback = function()
        vim.schedule(function()
          M.close(state)
        end)
      end,
    })
  end)
end

local function register_resize_hook(state, opts, prompt_bufnr)
  if not opts.resize then
    return
  end
  local id
  id = api.nvim_create_autocmd("VimResized", {
    callback = function()
      -- If the popup was already closed by some other path, drop the hook.
      if not state.open or not api.nvim_win_is_valid(state.km_win_id) then
        pcall(api.nvim_del_autocmd, id)
        return
      end
      M.close(state)
      -- Re-run on the next tick so the resize event finishes propagating
      -- through nvim's layout machinery before we recompute dimensions.
      vim.schedule(function()
        if api.nvim_buf_is_valid(prompt_bufnr) then
          M.run(prompt_bufnr, state.opts)
        end
      end)
      pcall(api.nvim_del_autocmd, id)
    end,
  })
  state.resize_autocmd = id
end

--- Close the popup window and delete its buffers. Idempotent.
function M.close(state)
  if not state or not state.open then
    return
  end
  state.open = false
  pcall(api.nvim_win_close, state.km_win_id, true)
  pcall(api.nvim_win_close, state.border_win_id, true)
  if state.km_buf and api.nvim_buf_is_valid(state.km_buf) then
    utils.buf_delete(state.km_buf)
  end
  if state.resize_autocmd then
    pcall(api.nvim_del_autocmd, state.resize_autocmd)
    state.resize_autocmd = nil
  end
end

--- Public entry point. Matches actions.which_key's signature.
---@param prompt_bufnr number
---@param opts table|nil
function M.run(prompt_bufnr, opts)
  opts = resolve_opts(opts)
  hl_mod.setup()

  if toggle_close() then
    return
  end

  local column_indent = table.concat(utils.repeated_table(opts.column_indent, " "))

  local mappings = mappings_mod.collect(prompt_bufnr, opts)
  if opts.categorize_mappings then
    mappings_mod.sort(mappings)
  else
    -- Legacy sort: by name, tie-breaking with normal mode first.
    table.sort(mappings, function(x, y)
      if x.name ~= y.name then
        return x.name < y.name
      end
      return x.mode > y.mode
    end)
  end

  local num_columns, num_rows, capacity = layout_mod.dimensions(mappings, opts, column_indent)

  local hidden_count = 0
  if opts.categorize_mappings then
    mappings, hidden_count = layout_mod.truncate(mappings, capacity, opts.category_drop_order)
    -- After truncation, recompute rows against the smaller set so the popup
    -- doesn't reserve empty space.
    num_rows = math.min(math.max(1, math.ceil(#mappings / num_columns)), num_rows)
  end

  opts.num_rows = num_rows
  local winheight = num_rows + 2 * opts.line_padding

  local picker = action_state.get_current_picker(prompt_bufnr)
  local prompt_pos = compute_placement(picker)

  local modes = { n = "Normal", i = "Insert" }
  local mode = api.nvim_get_mode().mode
  local title_mode = opts.only_show_current_mode and (modes[mode] or "") .. " Mode " or ""
  local title_text = title_mode .. "Keymaps"

  local popup_opts = {
    relative = "editor",
    enter = false,
    minwidth = vim.o.columns,
    maxwidth = vim.o.columns,
    minheight = winheight,
    maxheight = winheight,
    line = prompt_pos and (vim.o.lines - winheight + 1) or 1,
    col = 0,
    border = { prompt_pos and 1 or 0, 0, not prompt_pos and 1 or 0, 0 },
    borderchars = { prompt_pos and "─" or " ", "", not prompt_pos and "─" or " ", "", "", "", "", "" },
    noautocmd = true,
    title = { { text = title_text, pos = prompt_pos and "N" or "S" } },
    zindex = opts.zindex,
  }
  local km_win_id, km_opts = popup.create("", popup_opts)
  local km_buf = api.nvim_win_get_buf(km_win_id)
  api.nvim_buf_set_name(km_buf, M.WIN_BUFNAME)
  api.nvim_buf_set_name(km_opts.border.bufnr, M.BORDER_BUFNAME)
  vim.wo[km_win_id].winhl = "Normal:" .. opts.normal_hl
  vim.wo[km_opts.border.win_id].winhl = "Normal:" .. opts.border_hl
  vim.wo[km_win_id].winblend = opts.winblend
  vim.wo[km_win_id].foldenable = false

  -- Pre-fill the buffer with indent strings so we can append to each row.
  api.nvim_buf_set_lines(km_buf, 0, -1, false, utils.repeated_table(winheight, column_indent))

  local make_display = display_mod.make_display(opts, hl_mod)
  local ns = api.nvim_create_namespace("telescope_whichkey")
  local highlights = {}

  for index, mapping in ipairs(mappings) do
    local row = utils.cycle(index, num_rows) - 1 + opts.line_padding
    local prev_line = api.nvim_buf_get_lines(km_buf, row, row + 1, false)[1]

    if index > capacity then
      break
    end

    local display, display_hl = make_display(mapping)
    local new_line = prev_line .. display .. opts.column_padding
    api.nvim_buf_set_lines(km_buf, row, row + 1, false, { new_line })
    table.insert(highlights, { hl = display_hl, row = row, col = #prev_line })
  end

  if hidden_count > 0 then
    -- Append a "+N more" indicator at the tail of the last content row.
    local last_row = num_rows - 1 + opts.line_padding
    local prev_line = api.nvim_buf_get_lines(km_buf, last_row, last_row + 1, false)[1] or ""
    local new_line = prev_line .. string.format("… +%d more", hidden_count)
    api.nvim_buf_set_lines(km_buf, last_row, last_row + 1, false, { new_line })
  end

  for _, h in ipairs(highlights) do
    for _, hl_block in ipairs(h.hl) do
      utils.hl_range(
        km_buf,
        ns,
        hl_block[2],
        { h.row, h.col + hl_block[1][1] },
        { h.row, h.col + hl_block[1][2] }
      )
    end
  end

  local state = {
    open = true,
    km_win_id = km_win_id,
    km_buf = km_buf,
    border_win_id = km_opts.border.win_id,
    opts = opts,
  }

  register_close_hooks(state, opts, prompt_bufnr)
  register_resize_hook(state, opts, prompt_bufnr)
end

return M
