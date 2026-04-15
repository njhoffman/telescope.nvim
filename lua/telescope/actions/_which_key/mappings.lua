local action_utils = require("telescope.actions.utils")
local utils = require("telescope.utils")

local M = {}

--- Normalize an origin value returned by `utils.get_registered_mappings`.
--- Legacy descriptions without an origin suffix are treated as "default" so
--- older extensions that bypass apply_keymap don't end up uncategorized.
---@param origin string|nil
---@return string
local function normalize_origin(origin)
  if origin == "picker" or origin == "user_global" or origin == "default" then
    return origin
  end
  return "default"
end

--- Collect registered mappings for the picker, tagged with category/origin.
--- Emits a warning (once) when anonymous mappings are encountered because
--- their names are best-effort only.
---@param prompt_bufnr number
---@param opts table resolved which_key opts
---@return table[] mappings [{ mode, keybind, name, origin }]
function M.collect(prompt_bufnr, opts)
  local mappings = {}
  local mode = vim.api.nvim_get_mode().mode
  local seen_anon = false

  for _, v in pairs(action_utils.get_registered_mappings(prompt_bufnr)) do
    if v.desc and v.desc ~= "which_key" and v.desc ~= "nop" then
      if not opts.only_show_current_mode or mode == v.mode then
        table.insert(mappings, {
          mode = v.mode,
          keybind = v.keybind,
          name = v.desc,
          origin = normalize_origin(v.origin),
        })
        if v.desc == "<anonymous>" then
          seen_anon = true
        end
      end
    end
  end

  if seen_anon then
    utils.notify("actions.which_key", {
      msg = "No name available for anonymous functions.",
      level = "INFO",
      once = true,
    })
  end

  return mappings
end

--- Sort mappings: picker-specific first (most likely to be what the user
--- needs), then user_global, then defaults. Within a group, sort by name and
--- tie-break by mode (normal before insert).
---@param mappings table[]
function M.sort(mappings)
  local rank = { picker = 0, user_global = 1, default = 2 }
  table.sort(mappings, function(x, y)
    local rx, ry = rank[x.origin] or 3, rank[y.origin] or 3
    if rx ~= ry then
      return rx < ry
    end
    if x.name ~= y.name then
      return x.name < y.name
    end
    -- show normal mode as the standard mode first
    return x.mode > y.mode
  end)
end

return M
