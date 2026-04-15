local M = {}

-- Defines the highlight groups used by the which-key popup.
-- Each category (default / user_global / picker) has three groups
-- (Mode / Bind / Name) so themes can target any combination.
--
-- Groups are defined with { default = true } so user-defined highlight
-- overrides always win.
function M.setup()
  local sethl = function(name, link)
    vim.api.nvim_set_hl(0, name, { link = link, default = true })
  end

  -- Window chrome
  sethl("TelescopeWhichKeyNormal", "TelescopePrompt")
  sethl("TelescopeWhichKeyBorder", "TelescopePromptBorder")

  -- Default category (legacy behavior): links to the historical groups
  sethl("TelescopeWhichKeyDefaultMode", "TelescopeResultsConstant")
  sethl("TelescopeWhichKeyDefaultBind", "TelescopeResultsVariable")
  sethl("TelescopeWhichKeyDefaultName", "TelescopeResultsFunction")

  -- User-global category: visually distinct via Comment-like dim
  sethl("TelescopeWhichKeyUserMode", "TelescopeResultsConstant")
  sethl("TelescopeWhichKeyUserBind", "TelescopeResultsIdentifier")
  sethl("TelescopeWhichKeyUserName", "TelescopeResultsFunction")

  -- Picker-specific category: emphasized (keyword-bold)
  sethl("TelescopeWhichKeyPickerMode", "TelescopeResultsConstant")
  sethl("TelescopeWhichKeyPickerBind", "TelescopeResultsKeyword")
  sethl("TelescopeWhichKeyPickerName", "TelescopeResultsTitle")
end

--- Resolve the three-column highlight triple for a mapping's origin.
---@param origin string|nil one of "default" | "user_global" | "picker"
---@param opts table resolved which_key opts (for overrides)
---@return table { mode=string, keybind=string, name=string }
function M.for_origin(origin, opts)
  if origin == "picker" and opts.picker_hl then
    return opts.picker_hl
  elseif origin == "user_global" and opts.user_hl then
    return opts.user_hl
  elseif origin == "default" and opts.default_hl then
    return opts.default_hl
  end

  if origin == "picker" then
    return { mode = "TelescopeWhichKeyPickerMode", keybind = "TelescopeWhichKeyPickerBind", name = "TelescopeWhichKeyPickerName" }
  elseif origin == "user_global" then
    return { mode = "TelescopeWhichKeyUserMode", keybind = "TelescopeWhichKeyUserBind", name = "TelescopeWhichKeyUserName" }
  end
  -- Fall through (default / unknown): legacy behavior, respecting user
  -- overrides via mode_hl / keybind_hl / name_hl.
  return {
    mode = opts.mode_hl or "TelescopeWhichKeyDefaultMode",
    keybind = opts.keybind_hl or "TelescopeWhichKeyDefaultBind",
    name = opts.name_hl or "TelescopeWhichKeyDefaultName",
  }
end

return M
