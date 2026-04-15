local entry_display = require("telescope.pickers.entry_display")

local M = {}

-- Built-in key-label substitutions. Off by default unless the user sets
-- `use_default_key_labels = true` in the which_key opts. Kept small and
-- symbol-only so they don't break column widths.
M.DEFAULT_KEY_LABELS = {
  ["<CR>"] = "Enter",
  ["<Esc>"] = "Esc",
  ["<Tab>"] = "Tab",
  ["<S-Tab>"] = "S-Tab",
  ["<BS>"] = "BS",
  ["<Space>"] = "␣",
  ["<leader>"] = "<ldr>",
  ["<Up>"] = "↑",
  ["<Down>"] = "↓",
  ["<Left>"] = "←",
  ["<Right>"] = "→",
}

--- Apply key-code substitution: first a user `key_labels` table (exact
--- match), then any `replace_keys` pattern pairs (Lua patterns via
--- `string.gsub`).
---
--- Substitution is applied to the display string only; the underlying
--- mapping lhs is unchanged.
---@param keybind string raw mapping lhs (e.g. "<C-n>")
---@param opts table resolved which_key opts
---@return string substituted
function M.substitute(keybind, opts)
  local labels = opts.key_labels
  if opts.use_default_key_labels then
    labels = vim.tbl_extend("keep", labels or {}, M.DEFAULT_KEY_LABELS)
  end

  if labels and labels[keybind] then
    return labels[keybind]
  end

  local out = keybind
  if type(opts.replace_keys) == "table" then
    for _, pair in ipairs(opts.replace_keys) do
      local pattern, replacement = pair[1], pair[2]
      if type(pattern) == "string" and type(replacement) == "string" then
        out = out:gsub(pattern, replacement)
      end
    end
  end
  return out
end

--- Build the row formatter. Returns a function that takes a mapping and
--- yields a (line, highlight_table) tuple via telescope's entry_display.
---@param opts table resolved which_key opts
---@param highlights_mod table lua/telescope/actions/_which_key/highlights.lua
---@return fun(mapping: table): string, table
function M.make_display(opts, highlights_mod)
  local displayer = entry_display.create {
    separator = opts.separator,
    items = {
      { width = opts.mode_width },
      { width = opts.keybind_width },
      { width = opts.name_width },
    },
  }

  return function(mapping)
    local hl = highlights_mod.for_origin(mapping.origin, opts)
    local keybind = M.substitute(mapping.keybind, opts)
    return displayer {
      { mapping.mode, hl.mode },
      { keybind, hl.keybind },
      { mapping.name, hl.name },
    }
  end
end

return M
