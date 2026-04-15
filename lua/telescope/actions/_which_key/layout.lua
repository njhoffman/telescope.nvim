local resolver = require("telescope.config.resolve")

local M = {}

--- Entry width per column, matching the monolithic implementation.
---@param opts table resolved which_key opts
---@return number
function M.entry_width(opts)
  return #opts.column_padding + opts.mode_width + opts.keybind_width + opts.name_width + (3 * #opts.separator)
end

--- Compute the maximum number of entries that can fit given the current
--- editor dimensions and the configured max_height.
---@param mappings table[]
---@param opts table
---@param column_indent string
---@return number num_columns, number num_rows, number capacity
function M.dimensions(mappings, opts, column_indent)
  local entry_width = M.entry_width(opts)
  local num_columns = math.max(1, math.floor((vim.o.columns - #column_indent) / entry_width))
  local row_cap = resolver.resolve_height(opts.max_height)(_, _, vim.o.lines)
  local num_rows = math.min(math.max(1, math.ceil(#mappings / num_columns)), row_cap)
  return num_columns, num_rows, num_rows * num_columns
end

--- Apply priority-based truncation. When the mapping list exceeds capacity,
--- drop lower-priority categories in order (typically "default" first, then
--- "user_global"), keeping the "picker" tier intact.
---
--- Returns the (possibly pruned) list and the number of entries that were
--- dropped due to overflow so the caller can render an indicator.
---@param mappings table[]
---@param capacity number
---@param drop_order string[] e.g. { "default", "user_global" }
---@return table[] pruned, number hidden_count
function M.truncate(mappings, capacity, drop_order)
  if #mappings <= capacity then
    return mappings, 0
  end

  local by_origin = { default = {}, user_global = {}, picker = {} }
  for _, m in ipairs(mappings) do
    local bucket = by_origin[m.origin] or by_origin.default
    table.insert(bucket, m)
  end

  local dropped = 0
  for _, origin in ipairs(drop_order or { "default", "user_global" }) do
    if (#by_origin.default + #by_origin.user_global + #by_origin.picker) <= capacity then
      break
    end
    dropped = dropped + #(by_origin[origin] or {})
    by_origin[origin] = {}
  end

  -- If picker alone still overflows, clip it and report how many we hid
  local kept = {}
  for _, origin in ipairs({ "picker", "user_global", "default" }) do
    for _, m in ipairs(by_origin[origin] or {}) do
      table.insert(kept, m)
    end
  end

  local overflow = 0
  if #kept > capacity then
    overflow = #kept - capacity
    for _ = 1, overflow do
      table.remove(kept)
    end
  end

  return kept, dropped + overflow
end

return M
