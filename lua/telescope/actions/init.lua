---@tag telescope.actions
---@config { ["module"] = "telescope.actions" }

---@brief [[
--- These functions are useful for people creating their own mappings.
---
--- Actions can be either normal functions that expect the `prompt_bufnr` as
--- first argument (1) or they can be a custom telescope type called "action" (2).
---
--- (1) The `prompt_bufnr` of a normal function denotes the identifier of your
--- picker which can be used to access the picker state. In practice, users
--- most commonly access from both picker and global state via the following:
--- <code>
---   -- for utility functions
---   local action_state = require "telescope.actions.state"
---
---   local actions = {}
---   actions.do_stuff = function(prompt_bufnr)
---     local current_picker = action_state.get_current_picker(prompt_bufnr) -- picker state
---     local entry = action_state.get_selected_entry()
---   end
--- </code>
---
--- See |telescope.actions.state| for more information.
---
--- (2) To transform a module of functions into a module of "action"s, you need
--- to do the following:
--- <code>
---   local transform_mod = require("telescope.actions.mt").transform_mod
---
---   local mod = {}
---   mod.a1 = function(prompt_bufnr)
---     -- your code goes here
---     -- You can access the picker/global state as described above in (1).
---   end
---
---   mod.a2 = function(prompt_bufnr)
---     -- your code goes here
---   end
---   mod = transform_mod(mod)
---
---   -- Now the following is possible. This means that actions a2 will be executed
---   -- after action a1. You can chain as many actions as you want.
---   local action = mod.a1 + mod.a2
---   action(bufnr)
--- </code>
---
--- Another interesting thing to do is that these actions now have functions you
--- can call. These functions include `:replace(f)`, `:replace_if(f, c)`,
--- `replace_map(tbl)` and `enhance(tbl)`. More information on these functions
--- can be found in the `developers.md` and `lua/tests/automated/action_spec.lua`
--- file.
---@brief ]]

local api = vim.api

local conf = require("telescope.config").values
local state = require "telescope.state"
local utils = require "telescope.utils"
local p_scroller = require "telescope.pickers.scroller"

local action_state = require "telescope.actions.state"
local action_utils = require "telescope.actions.utils"

local git_command = utils.__git_command
local function picker_git_opts(prompt_bufnr)
  local picker = action_state.get_current_picker(prompt_bufnr)
  return { cwd = picker.cwd, gitdir = picker.gitdir, toplevel = picker.toplevel }
end
local action_set = require "telescope.actions.set"
local from_entry = require "telescope.from_entry"

local transform_mod = require("telescope.actions.mt").transform_mod

local actions = setmetatable({}, {
  __index = function(_, k)
    error("Key does not exist for 'telescope.actions': " .. tostring(k))
  end,
})

local append_to_history = function(prompt_bufnr)
  action_state
    .get_current_history()
    :append(action_state.get_current_line(), action_state.get_current_picker(prompt_bufnr))
end

--- Move the selection to the next entry
---@param prompt_bufnr number: The prompt bufnr
actions.move_selection_next = function(prompt_bufnr)
  action_set.shift_selection(prompt_bufnr, 1)
end

--- Move the selection to the previous entry
---@param prompt_bufnr number: The prompt bufnr
actions.move_selection_previous = function(prompt_bufnr)
  action_set.shift_selection(prompt_bufnr, -1)
end

--- Move the selection to the entry that has a worse score
---@param prompt_bufnr number: The prompt bufnr
actions.move_selection_worse = function(prompt_bufnr)
  local picker = action_state.get_current_picker(prompt_bufnr)
  action_set.shift_selection(prompt_bufnr, p_scroller.worse(picker.sorting_strategy))
end

--- Move the selection to the entry that has a better score
---@param prompt_bufnr number: The prompt bufnr
actions.move_selection_better = function(prompt_bufnr)
  local picker = action_state.get_current_picker(prompt_bufnr)
  action_set.shift_selection(prompt_bufnr, p_scroller.better(picker.sorting_strategy))
end

--- Move to the top of the picker
---@param prompt_bufnr number: The prompt bufnr
actions.move_to_top = function(prompt_bufnr)
  local current_picker = action_state.get_current_picker(prompt_bufnr)
  current_picker:set_selection(
    p_scroller.top(current_picker.sorting_strategy, current_picker.max_results, current_picker.manager:num_results())
  )
end

--- Move to the middle of the picker
---@param prompt_bufnr number: The prompt bufnr
actions.move_to_middle = function(prompt_bufnr)
  local current_picker = action_state.get_current_picker(prompt_bufnr)
  current_picker:set_selection(
    p_scroller.middle(current_picker.sorting_strategy, current_picker.max_results, current_picker.manager:num_results())
  )
end

--- Move to the bottom of the picker
---@param prompt_bufnr number: The prompt bufnr
actions.move_to_bottom = function(prompt_bufnr)
  local current_picker = action_state.get_current_picker(prompt_bufnr)
  current_picker:set_selection(
    p_scroller.bottom(current_picker.sorting_strategy, current_picker.max_results, current_picker.manager:num_results())
  )
end

--- Add current entry to multi select
---@param prompt_bufnr number: The prompt bufnr
actions.add_selection = function(prompt_bufnr)
  local current_picker = action_state.get_current_picker(prompt_bufnr)
  current_picker:add_selection(current_picker:get_selection_row())
end

--- Remove current entry from multi select
---@param prompt_bufnr number: The prompt bufnr
actions.remove_selection = function(prompt_bufnr)
  local current_picker = action_state.get_current_picker(prompt_bufnr)
  current_picker:remove_selection(current_picker:get_selection_row())
end

--- Toggle current entry status for multi select
---@param prompt_bufnr number: The prompt bufnr
actions.toggle_selection = function(prompt_bufnr)
  local current_picker = action_state.get_current_picker(prompt_bufnr)
  current_picker:toggle_selection(current_picker:get_selection_row())
end

--- Multi select all entries.
--- - Note: selected entries may include results not visible in the results pop up.
---@param prompt_bufnr number: The prompt bufnr
actions.select_all = function(prompt_bufnr)
  local current_picker = action_state.get_current_picker(prompt_bufnr)
  action_utils.map_entries(prompt_bufnr, function(entry, _, row)
    if not current_picker._multi:is_selected(entry) then
      current_picker._multi:add(entry)
      if current_picker:can_select_row(row) then
        local caret = current_picker:update_prefix(entry, row)
        if current_picker._selection_entry == entry and current_picker._selection_row == row then
          current_picker.highlighter:hi_selection(row, caret:match "(.*%S)")
        end
        current_picker.highlighter:hi_multiselect(row, current_picker._multi:is_selected(entry))
      end
    end
  end)
  current_picker:get_status_updater(current_picker.prompt_win, current_picker.prompt_bufnr)()
end

--- Drop all entries from the current multi selection.
---@param prompt_bufnr number: The prompt bufnr
actions.drop_all = function(prompt_bufnr)
  local current_picker = action_state.get_current_picker(prompt_bufnr)
  action_utils.map_entries(prompt_bufnr, function(entry, _, row)
    current_picker._multi:drop(entry)
    if current_picker:can_select_row(row) then
      local caret = current_picker:update_prefix(entry, row)
      if current_picker._selection_entry == entry and current_picker._selection_row == row then
        current_picker.highlighter:hi_selection(row, caret:match "(.*%S)")
      end
      current_picker.highlighter:hi_multiselect(row, current_picker._multi:is_selected(entry))
    end
  end)
  current_picker:get_status_updater(current_picker.prompt_win, current_picker.prompt_bufnr)()
end

--- Toggle multi selection for all entries.
--- - Note: toggled entries may include results not visible in the results pop up.
---@param prompt_bufnr number: The prompt bufnr
actions.toggle_all = function(prompt_bufnr)
  local current_picker = action_state.get_current_picker(prompt_bufnr)
  action_utils.map_entries(prompt_bufnr, function(entry, _, row)
    current_picker._multi:toggle(entry)
    if current_picker:can_select_row(row) then
      local caret = current_picker:update_prefix(entry, row)
      if current_picker._selection_entry == entry and current_picker._selection_row == row then
        current_picker.highlighter:hi_selection(row, caret:match "(.*%S)")
      end
      current_picker.highlighter:hi_multiselect(row, current_picker._multi:is_selected(entry))
    end
  end)
  current_picker:get_status_updater(current_picker.prompt_win, current_picker.prompt_bufnr)()
end

--- Scroll the preview window up
---@param prompt_bufnr number: The prompt bufnr
actions.preview_scrolling_up = function(prompt_bufnr)
  action_set.scroll_previewer(prompt_bufnr, -1)
end

--- Scroll the preview window down
---@param prompt_bufnr number: The prompt bufnr
actions.preview_scrolling_down = function(prompt_bufnr)
  action_set.scroll_previewer(prompt_bufnr, 1)
end

--- Scroll the preview window up by one line
---@param prompt_bufnr number: The prompt bufnr
actions.preview_scrolling_up_line = function(prompt_bufnr)
  action_set.scroll_previewer_by(prompt_bufnr, -1)
end

--- Scroll the preview window down by one line
---@param prompt_bufnr number: The prompt bufnr
actions.preview_scrolling_down_line = function(prompt_bufnr)
  action_set.scroll_previewer_by(prompt_bufnr, 1)
end

--- Scroll the preview window up by one full page (preview window height)
---@param prompt_bufnr number: The prompt bufnr
actions.preview_scrolling_page_up = function(prompt_bufnr)
  action_set.scroll_previewer_page(prompt_bufnr, -1)
end

--- Scroll the preview window down by one full page (preview window height)
---@param prompt_bufnr number: The prompt bufnr
actions.preview_scrolling_page_down = function(prompt_bufnr)
  action_set.scroll_previewer_page(prompt_bufnr, 1)
end

--- Smoothly scroll the preview window up by one line
---@param prompt_bufnr number: The prompt bufnr
actions.preview_smoothscrolling_up_line = function(prompt_bufnr)
  action_set.smoothscroll_previewer_by(prompt_bufnr, -1)
end

--- Smoothly scroll the preview window down by one line
---@param prompt_bufnr number: The prompt bufnr
actions.preview_smoothscrolling_down_line = function(prompt_bufnr)
  action_set.smoothscroll_previewer_by(prompt_bufnr, 1)
end

--- Smoothly scroll the preview window up by one full page (preview window height)
---@param prompt_bufnr number: The prompt bufnr
actions.preview_smoothscrolling_page_up = function(prompt_bufnr)
  action_set.smoothscroll_previewer_page(prompt_bufnr, -1)
end

--- Smoothly scroll the preview window down by one full page (preview window height)
---@param prompt_bufnr number: The prompt bufnr
actions.preview_smoothscrolling_page_down = function(prompt_bufnr)
  action_set.smoothscroll_previewer_page(prompt_bufnr, 1)
end

--- Scroll the preview window to the left
---@param prompt_bufnr number: The prompt bufnr
actions.preview_scrolling_left = function(prompt_bufnr)
  action_set.scroll_horizontal_previewer(prompt_bufnr, -1)
end

--- Scroll the preview window to the right
---@param prompt_bufnr number: The prompt bufnr
actions.preview_scrolling_right = function(prompt_bufnr)
  action_set.scroll_horizontal_previewer(prompt_bufnr, 1)
end

--- Scroll the results window up
---@param prompt_bufnr number: The prompt bufnr
actions.results_scrolling_up = function(prompt_bufnr)
  action_set.scroll_results(prompt_bufnr, -1)
end

--- Scroll the results window down
---@param prompt_bufnr number: The prompt bufnr
actions.results_scrolling_down = function(prompt_bufnr)
  action_set.scroll_results(prompt_bufnr, 1)
end

--- Scroll the results window to the left
---@param prompt_bufnr number: The prompt bufnr
actions.results_scrolling_left = function(prompt_bufnr)
  action_set.scroll_horizontal_results(prompt_bufnr, -1)
end

--- Scroll the results window to the right
---@param prompt_bufnr number: The prompt bufnr
actions.results_scrolling_right = function(prompt_bufnr)
  action_set.scroll_horizontal_results(prompt_bufnr, 1)
end

--- Center the cursor in the window, can be used after selecting a file to edit
--- You can just map `actions.select_default + actions.center`
---@param prompt_bufnr number: The prompt bufnr
actions.center = function(prompt_bufnr)
  vim.cmd ":normal! zz"
end

--- Perform default action on selection, usually something like<br>
--- `:edit <selection>`
---
--- i.e. open the selection in the current buffer
---@param prompt_bufnr number: The prompt bufnr
actions.select_default = {
  pre = append_to_history,
  action = function(prompt_bufnr)
    return action_set.select(prompt_bufnr, "default")
  end,
}

--- Perform 'horizontal' action on selection, usually something like<br>
---`:new <selection>`
---
--- i.e. open the selection in a new horizontal split
---@param prompt_bufnr number: The prompt bufnr
actions.select_horizontal = {
  pre = append_to_history,
  action = function(prompt_bufnr)
    return action_set.select(prompt_bufnr, "horizontal")
  end,
}

--- Perform 'vertical' action on selection, usually something like<br>
---`:vnew <selection>`
---
--- i.e. open the selection in a new vertical split
---@param prompt_bufnr number: The prompt bufnr
actions.select_vertical = {
  pre = append_to_history,
  action = function(prompt_bufnr)
    return action_set.select(prompt_bufnr, "vertical")
  end,
}

--- Perform 'tab' action on selection, usually something like<br>
---`:tabedit <selection>`
---
--- i.e. open the selection in a new tab
---@param prompt_bufnr number: The prompt bufnr
actions.select_tab = {
  pre = append_to_history,
  action = function(prompt_bufnr)
    return action_set.select(prompt_bufnr, "tab")
  end,
}

--- Perform 'drop' action on selection, usually something like<br>
---`:drop <selection>`
---
--- i.e. open the selection in a window
---@param prompt_bufnr number: The prompt bufnr
actions.select_drop = {
  pre = append_to_history,
  action = function(prompt_bufnr)
    return action_set.select(prompt_bufnr, "drop")
  end,
}

--- Perform 'tab drop' action on selection, usually something like<br>
---`:tab drop <selection>`
---
--- i.e. open the selection in a new tab
---@param prompt_bufnr number: The prompt bufnr
actions.select_tab_drop = {
  pre = append_to_history,
  action = function(prompt_bufnr)
    return action_set.select(prompt_bufnr, "tab drop")
  end,
}

-- TODO: consider adding float!
-- https://github.com/nvim-telescope/telescope.nvim/issues/365

--- Perform file edit on selection, usually something like<br>
--- `:edit <selection>`
---@param prompt_bufnr number: The prompt bufnr
actions.file_edit = function(prompt_bufnr)
  return action_set.edit(prompt_bufnr, "edit")
end

--- Perform file split on selection, usually something like<br>
--- `:new <selection>`
---@param prompt_bufnr number: The prompt bufnr
actions.file_split = function(prompt_bufnr)
  return action_set.edit(prompt_bufnr, "new")
end

--- Perform file vsplit on selection, usually something like<br>
--- `:vnew <selection>`
---@param prompt_bufnr number: The prompt bufnr
actions.file_vsplit = function(prompt_bufnr)
  return action_set.edit(prompt_bufnr, "vnew")
end

--- Perform file tab on selection, usually something like<br>
--- `:tabedit <selection>`
---@param prompt_bufnr number: The prompt bufnr
actions.file_tab = function(prompt_bufnr)
  return action_set.edit(prompt_bufnr, "tabedit")
end

actions.close_pum = function(_)
  if 0 ~= vim.fn.pumvisible() then
    api.nvim_feedkeys(api.nvim_replace_termcodes("<c-y>", true, true, true), "n", true)
  end
end

--- Close the Telescope window, usually used within an action
---@param prompt_bufnr number: The prompt bufnr
actions.close = function(prompt_bufnr)
  local picker = action_state.get_current_picker(prompt_bufnr)
  local original_win_id = picker.original_win_id
  local cursor_valid, original_cursor = pcall(api.nvim_win_get_cursor, original_win_id)

  actions.close_pum(prompt_bufnr)

  require("telescope.pickers").on_close_prompt(prompt_bufnr)
  pcall(api.nvim_set_current_win, original_win_id)
  if cursor_valid and api.nvim_get_mode().mode == "i" and picker._original_mode ~= "i" then
    pcall(api.nvim_win_set_cursor, original_win_id, { original_cursor[1], original_cursor[2] + 1 })
  end
end

--- Close the Telescope window, usually used within an action<br>
--- Deprecated and no longer needed, does the same as |telescope.actions.close|. Might be removed in the future
---@deprecated
---@param prompt_bufnr number: The prompt bufnr
actions._close = function(prompt_bufnr)
  actions.close(prompt_bufnr)
end

local set_edit_line = function(prompt_bufnr, fname, prefix, postfix)
  postfix = vim.F.if_nil(postfix, "")
  postfix = api.nvim_replace_termcodes(postfix, true, false, true)
  local selection = action_state.get_selected_entry()
  if selection == nil then
    utils.__warn_no_selection(fname)
    return
  end
  actions.close(prompt_bufnr)
  api.nvim_feedkeys(prefix .. selection.value .. postfix, "n", true)
end

--- Set a value in the command line and don't run it, making it editable.
---@param prompt_bufnr number: The prompt bufnr
actions.edit_command_line = function(prompt_bufnr)
  set_edit_line(prompt_bufnr, "actions.edit_command_line", ":")
end

--- Set a value in the command line and run it
---@param prompt_bufnr number: The prompt bufnr
actions.set_command_line = function(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  if selection == nil then
    utils.__warn_no_selection "actions.set_command_line"
    return
  end
  actions.close(prompt_bufnr)
  vim.fn.histadd("cmd", selection.value)
  vim.cmd(selection.value)
end

--- Set a value in the search line and don't search for it, making it editable.
---@param prompt_bufnr number: The prompt bufnr
actions.edit_search_line = function(prompt_bufnr)
  set_edit_line(prompt_bufnr, "actions.edit_search_line", "/")
end

--- Set a value in the search line and search for it
---@param prompt_bufnr number: The prompt bufnr
actions.set_search_line = function(prompt_bufnr)
  set_edit_line(prompt_bufnr, "actions.set_search_line", "/", "<CR>")
end

--- Edit a register
---@param prompt_bufnr number: The prompt bufnr
actions.edit_register = function(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  local picker = action_state.get_current_picker(prompt_bufnr)

  vim.fn.inputsave()
  local updated_value = vim.fn.input("Edit [" .. selection.value .. "] ❯ ", selection.content)
  vim.fn.inputrestore()
  if updated_value ~= selection.content then
    vim.fn.setreg(selection.value, updated_value)
    selection.content = updated_value
  end

  -- update entry in results table
  -- TODO: find way to redraw finder content
  for _, v in pairs(picker.finder.results) do
    if v == selection then
      v.content = updated_value
    end
  end
end

--- Paste the selected register into the buffer
---
--- Note: only meant to be used inside builtin.registers
---@param prompt_bufnr number: The prompt bufnr
actions.paste_register = function(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  if selection == nil then
    utils.__warn_no_selection "actions.paste_register"
    return
  end

  actions.close(prompt_bufnr)

  -- ensure that the buffer can be written to
  if vim.bo[0].modifiable then
    api.nvim_paste(selection.content, true, -1)
  end
end

--- Insert a symbol into the current buffer (while switching to normal mode)
---@param prompt_bufnr number: The prompt bufnr
actions.insert_symbol = function(prompt_bufnr)
  local symbol = action_state.get_selected_entry().value[1]
  actions.close(prompt_bufnr)
  vim.schedule(function()
    api.nvim_put({ symbol }, "", true, true)
  end)
end

--- Insert a symbol into the current buffer and keeping the insert mode.
---@param prompt_bufnr number: The prompt bufnr
actions.insert_symbol_i = function(prompt_bufnr)
  local symbol = action_state.get_selected_entry().value[1]
  actions.close(prompt_bufnr)
  vim.schedule(function()
    vim.cmd [[startinsert]]
    api.nvim_put({ symbol }, "", true, true)
  end)
end

-- TODO: Think about how to do this.
actions.insert_value = function(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  if selection == nil then
    utils.__warn_no_selection "actions.insert_value"
    return
  end

  vim.schedule(function()
    actions.close(prompt_bufnr)
  end)

  return selection.value
end

--- Ask user to confirm an action
---@param prompt string: The prompt for confirmation
---@param default_value string: The default value of user input
---@param yes_values table: List of positive user confirmations ({"y", "yes"} by default)
---@return boolean: Whether user confirmed the prompt
local function ask_to_confirm(prompt, default_value, yes_values)
  yes_values = yes_values or { "y", "yes" }
  default_value = default_value or ""
  local confirmation = vim.fn.input(prompt, default_value)
  confirmation = string.lower(confirmation)
  if string.len(confirmation) == 0 then
    return false
  end
  for _, v in pairs(yes_values) do
    if v == confirmation then
      return true
    end
  end
  return false
end

--- Create and checkout a new git branch if it doesn't already exist
---@param prompt_bufnr number: The prompt bufnr
actions.git_create_branch = function(prompt_bufnr)
  local gopts = picker_git_opts(prompt_bufnr)
  local new_branch = action_state.get_current_line()

  if new_branch == "" then
    utils.notify("actions.git_create_branch", {
      msg = "Missing the new branch name",
      level = "ERROR",
    })
  else
    local confirmation = ask_to_confirm(string.format("Create new branch '%s'? [y/n]: ", new_branch))
    if not confirmation then
      utils.notify("actions.git_create_branch", {
        msg = string.format("branch creation canceled: '%s'", new_branch),
        level = "INFO",
      })
      return
    end

    actions.close(prompt_bufnr)

    local _, ret, stderr = utils.get_os_command_output(git_command({ "checkout", "-b", new_branch }, gopts), gopts.cwd)
    if ret == 0 then
      utils.notify("actions.git_create_branch", {
        msg = string.format("Switched to a new branch: %s", new_branch),
        level = "INFO",
      })
    else
      utils.notify("actions.git_create_branch", {
        msg = string.format(
          "Error when creating new branch: '%s' Git returned '%s'",
          new_branch,
          table.concat(stderr, " ")
        ),
        level = "INFO",
      })
    end
  end
end

--- Applies an existing git stash
---@param prompt_bufnr number: The prompt bufnr
actions.git_apply_stash = function(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  if selection == nil then
    utils.__warn_no_selection "actions.git_apply_stash"
    return
  end
  local gopts = picker_git_opts(prompt_bufnr)
  actions.close(prompt_bufnr)
  local cmd = git_command({ "stash", "apply", "--index", selection.value }, gopts)
  local _, ret, stderr = utils.get_os_command_output(cmd, gopts.cwd)
  if ret == 0 then
    utils.notify("actions.git_apply_stash", {
      msg = string.format("applied: '%s' ", selection.value),
      level = "INFO",
    })
  else
    utils.notify("actions.git_apply_stash", {
      msg = string.format("Error when applying: %s. Git returned: '%s'", selection.value, table.concat(stderr, " ")),
      level = "ERROR",
    })
  end
end

--- Checkout an existing git branch
---@param prompt_bufnr number: The prompt bufnr
actions.git_checkout = function(prompt_bufnr)
  local gopts = picker_git_opts(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  if selection == nil then
    utils.__warn_no_selection "actions.git_checkout"
    return
  end
  actions.close(prompt_bufnr)
  local _, ret, stderr = utils.get_os_command_output(git_command({ "checkout", selection.value }, gopts), gopts.cwd)
  if ret == 0 then
    utils.notify("actions.git_checkout", {
      msg = string.format("Checked out: %s", selection.value),
      level = "INFO",
    })
    vim.cmd "checktime"
  else
    utils.notify("actions.git_checkout", {
      msg = string.format(
        "Error when checking out: %s. Git returned: '%s'",
        selection.value,
        table.concat(stderr, " ")
      ),
      level = "ERROR",
    })
  end
end

--- Switch to git branch.<br>
--- If the branch already exists in local, switch to that.
--- If the branch is only in remote, create new branch tracking remote and switch to new one.
---@param prompt_bufnr number: The prompt bufnr
actions.git_switch_branch = function(prompt_bufnr)
  local gopts = picker_git_opts(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  if selection == nil then
    utils.__warn_no_selection "actions.git_switch_branch"
    return
  end
  actions.close(prompt_bufnr)
  local pattern = "^refs/remotes/%w+/"
  local branch = selection.value
  if string.match(selection.refname, pattern) then
    branch = string.gsub(selection.refname, pattern, "")
  end
  local _, ret, stderr = utils.get_os_command_output(git_command({ "switch", branch }, gopts), gopts.cwd)
  if ret == 0 then
    utils.notify("actions.git_switch_branch", {
      msg = string.format("Switched to: '%s'", branch),
      level = "INFO",
    })
  else
    utils.notify("actions.git_switch_branch", {
      msg = string.format(
        "Error when switching to: %s. Git returned: '%s'",
        selection.value,
        table.concat(stderr, " ")
      ),
      level = "ERROR",
    })
  end
end

--- Action to rename selected git branch
--- @param prompt_bufnr number: The prompt bufnr
actions.git_rename_branch = function(prompt_bufnr)
  local gopts = picker_git_opts(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  if selection == nil then
    utils.__warn_no_selection "actions.git_rename_branch"
    return
  end
  -- Keeps the selected branch name for the input that asks for the new branch name
  local new_branch = vim.fn.input("New branch name: ", selection.value)
  if new_branch == "" then
    utils.notify("actions.git_rename_branch", {
      msg = "Missing the new branch name",
      level = "ERROR",
    })
  else
    actions.close(prompt_bufnr)
    local cmd = git_command({ "branch", "-m", selection.value, new_branch }, gopts)
    local _, ret, stderr = utils.get_os_command_output(cmd, gopts.cwd)
    if ret == 0 then
      utils.notify("actions.git_rename_branch", {
        msg = string.format("Renamed branch: '%s'", selection.value),
        level = "INFO",
      })
    else
      utils.notify("actions.git_rename_branch", {
        msg = string.format(
          "Error when renaming branch: %s. Git returned: '%s'",
          selection.value,
          table.concat(stderr, " ")
        ),
        level = "ERROR",
      })
    end
  end
end

local function make_git_branch_action(opts)
  return function(prompt_bufnr)
    local gopts = picker_git_opts(prompt_bufnr)
    local selection = action_state.get_selected_entry()
    if selection == nil then
      utils.__warn_no_selection(opts.action_name)
      return
    end

    local should_confirm = opts.should_confirm
    if should_confirm then
      local confirmation = ask_to_confirm(string.format(opts.confirmation_question, selection.value), "y")
      if not confirmation then
        utils.notify(opts.action_name, {
          msg = "action canceled",
          level = "INFO",
        })
        return
      end
    end

    actions.close(prompt_bufnr)
    local cmd = opts.command(selection.value)
    -- Strip leading "git" from command since git_command() prepends it with --git-dir/--work-tree
    if cmd[1] == "git" then
      table.remove(cmd, 1)
    end
    local _, ret, stderr = utils.get_os_command_output(git_command(cmd, gopts), gopts.cwd)
    if ret == 0 then
      utils.notify(opts.action_name, {
        msg = string.format(opts.success_message, selection.value),
        level = "INFO",
      })
    else
      utils.notify(opts.action_name, {
        msg = string.format(opts.error_message, selection.value, table.concat(stderr, " ")),
        level = "ERROR",
      })
    end
  end
end

--- Tell git to track the currently selected remote branch in Telescope
---@param prompt_bufnr number: The prompt bufnr
actions.git_track_branch = make_git_branch_action {
  should_confirm = false,
  action_name = "actions.git_track_branch",
  success_message = "Tracking branch: %s",
  error_message = "Error when tracking branch: %s. Git returned: '%s'",
  command = function(branch_name)
    return { "git", "checkout", "--track", branch_name }
  end,
}

--- Delete all currently selected branches
---@param prompt_bufnr number: The prompt bufnr
actions.git_delete_branch = function(prompt_bufnr)
  local confirmation = ask_to_confirm("Do you really want to delete the selected branches? [Y/n] ", "y")
  if not confirmation then
    utils.notify("actions.git_delete_branch", {
      msg = "action canceled",
      level = "INFO",
    })
    return
  end

  local picker = action_state.get_current_picker(prompt_bufnr)
  local gopts = { cwd = picker.cwd, gitdir = picker.gitdir, toplevel = picker.toplevel }
  local action_name = "actions.git_delete_branch"
  picker:delete_selection(function(selection)
    local branch = selection.value
    print("Deleting branch " .. branch)
    local _, ret, stderr = utils.get_os_command_output(git_command({ "branch", "-D", branch }, gopts), gopts.cwd)
    if ret == 0 then
      utils.notify(action_name, {
        msg = string.format("Deleted branch: %s", branch),
        level = "INFO",
      })
    else
      utils.notify(action_name, {
        msg = string.format("Error when deleting branch: %s. Git returned: '%s'", branch, table.concat(stderr, " ")),
        level = "ERROR",
      })
    end
    return ret == 0
  end)
end

--- Merge the currently selected branch
---@param prompt_bufnr number: The prompt bufnr
actions.git_merge_branch = make_git_branch_action {
  should_confirm = true,
  action_name = "actions.git_merge_branch",
  confirmation_question = "Do you really want to merge branch %s? [Y/n] ",
  success_message = "Merged branch: %s",
  error_message = "Error when merging branch: %s. Git returned: '%s'",
  command = function(branch_name)
    return { "git", "merge", branch_name }
  end,
}

--- Rebase to selected git branch
---@param prompt_bufnr number: The prompt bufnr
actions.git_rebase_branch = make_git_branch_action {
  should_confirm = true,
  action_name = "actions.git_rebase_branch",
  confirmation_question = "Do you really want to rebase branch %s? [Y/n] ",
  success_message = "Rebased branch: %s",
  error_message = "Error when rebasing branch: %s. Git returned: '%s'",
  command = function(branch_name)
    return { "git", "rebase", branch_name }
  end,
}

local git_reset_branch = function(prompt_bufnr, mode)
  local gopts = picker_git_opts(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  if selection == nil then
    utils.__warn_no_selection "actions.git_reset_branch"
    return
  end

  local confirmation =
    ask_to_confirm("Do you really want to " .. mode .. " reset to " .. selection.value .. "? [Y/n] ", "y")
  if not confirmation then
    utils.notify("actions.git_reset_branch", {
      msg = "action canceled",
      level = "INFO",
    })
    return
  end

  actions.close(prompt_bufnr)
  local _, ret, stderr = utils.get_os_command_output(git_command({ "reset", mode, selection.value }, gopts), gopts.cwd)
  if ret == 0 then
    utils.notify("actions.git_rebase_branch", {
      msg = string.format("Reset to: '%s'", selection.value),
      level = "INFO",
    })
  else
    utils.notify("actions.git_rebase_branch", {
      msg = string.format("Rest to: %s. Git returned: '%s'", selection.value, table.concat(stderr, " ")),
      level = "ERROR",
    })
  end
end

--- Reset to selected git commit using mixed mode
---@param prompt_bufnr number: The prompt bufnr
actions.git_reset_mixed = function(prompt_bufnr)
  git_reset_branch(prompt_bufnr, "--mixed")
end

--- Reset to selected git commit using soft mode
---@param prompt_bufnr number: The prompt bufnr
actions.git_reset_soft = function(prompt_bufnr)
  git_reset_branch(prompt_bufnr, "--soft")
end

--- Reset to selected git commit using hard mode
---@param prompt_bufnr number: The prompt bufnr
actions.git_reset_hard = function(prompt_bufnr)
  git_reset_branch(prompt_bufnr, "--hard")
end

--- Checkout a specific file for a given sha
---@param prompt_bufnr number: The prompt bufnr
actions.git_checkout_current_buffer = function(prompt_bufnr)
  local gopts = picker_git_opts(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  if selection == nil then
    utils.__warn_no_selection "actions.git_checkout_current_buffer"

    return
  end
  actions.close(prompt_bufnr)
  local cmd = git_command({ "checkout", selection.value, "--", selection.current_file }, gopts)
  utils.get_os_command_output(cmd, gopts.cwd)
  vim.cmd "checktime"
end

--- Stage/unstage selected file
---@param prompt_bufnr number: The prompt bufnr
actions.git_staging_toggle = function(prompt_bufnr)
  local gopts = picker_git_opts(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  if selection == nil then
    utils.__warn_no_selection "actions.git_staging_toggle"
    return
  end
  if selection.status:sub(2) == " " then
    utils.get_os_command_output(git_command({ "restore", "--staged", selection.value }, gopts), gopts.cwd)
  else
    utils.get_os_command_output(git_command({ "add", selection.value }, gopts), gopts.cwd)
  end
end

local entry_to_qf = function(entry)
  local text = entry.text

  if not text then
    if type(entry.value) == "table" then
      text = entry.value.text
    else
      text = entry.value
    end
  end

  return {
    bufnr = entry.bufnr,
    filename = from_entry.path(entry, false, false),
    lnum = vim.F.if_nil(entry.lnum, 1),
    col = vim.F.if_nil(entry.col, 1),
    text = text,
    type = entry.qf_type,
  }
end

local send_selected_to_qf = function(prompt_bufnr, mode, target)
  local picker = action_state.get_current_picker(prompt_bufnr)

  local qf_entries = {}
  for _, entry in ipairs(picker:get_multi_selection()) do
    table.insert(qf_entries, entry_to_qf(entry))
  end

  local prompt = picker:_get_prompt()
  actions.close(prompt_bufnr)

  api.nvim_exec_autocmds("QuickFixCmdPre", {})
  if target == "loclist" then
    vim.fn.setloclist(picker.original_win_id, qf_entries, mode)
  else
    local qf_title = string.format([[%s (%s)]], picker.prompt_title, prompt)
    vim.fn.setqflist(qf_entries, mode)
    vim.fn.setqflist({}, "a", { title = qf_title })
  end
  api.nvim_exec_autocmds("QuickFixCmdPost", {})
end

local send_all_to_qf = function(prompt_bufnr, mode, target)
  local picker = action_state.get_current_picker(prompt_bufnr)
  local manager = picker.manager

  local qf_entries = {}
  for entry in manager:iter() do
    table.insert(qf_entries, entry_to_qf(entry))
  end

  local prompt = picker:_get_prompt()
  actions.close(prompt_bufnr)

  api.nvim_exec_autocmds("QuickFixCmdPre", {})
  local qf_title = string.format([[%s (%s)]], picker.prompt_title, prompt)
  if target == "loclist" then
    vim.fn.setloclist(picker.original_win_id, qf_entries, mode)
    vim.fn.setloclist(picker.original_win_id, {}, "a", { title = qf_title })
  else
    vim.fn.setqflist(qf_entries, mode)
    vim.fn.setqflist({}, "a", { title = qf_title })
  end
  api.nvim_exec_autocmds("QuickFixCmdPost", {})
end

--- Sends the selected entries to the quickfix list, replacing the previous entries.
---@param prompt_bufnr number: The prompt bufnr
actions.send_selected_to_qflist = {
  pre = append_to_history,
  action = function(prompt_bufnr)
    send_selected_to_qf(prompt_bufnr, " ")
  end,
}
--- Adds the selected entries to the quickfix list, keeping the previous entries.
---@param prompt_bufnr number: The prompt bufnr
actions.add_selected_to_qflist = {
  pre = append_to_history,
  action = function(prompt_bufnr)
    send_selected_to_qf(prompt_bufnr, "a")
  end,
}
--- Sends all entries to the quickfix list, replacing the previous entries.
---@param prompt_bufnr number: The prompt bufnr
actions.send_to_qflist = {
  pre = append_to_history,
  action = function(prompt_bufnr)
    send_all_to_qf(prompt_bufnr, " ")
  end,
}
--- Adds all entries to the quickfix list, keeping the previous entries.
---@param prompt_bufnr number: The prompt bufnr
actions.add_to_qflist = {
  pre = append_to_history,
  action = function(prompt_bufnr)
    send_all_to_qf(prompt_bufnr, "a")
  end,
}
--- Sends the selected entries to the location list, replacing the previous entries.
---@param prompt_bufnr number: The prompt bufnr
actions.send_selected_to_loclist = {
  pre = append_to_history,
  action = function(prompt_bufnr)
    send_selected_to_qf(prompt_bufnr, " ", "loclist")
  end,
}
--- Adds the selected entries to the location list, keeping the previous entries.
---@param prompt_bufnr number: The prompt bufnr
actions.add_selected_to_loclist = {
  pre = append_to_history,
  action = function(prompt_bufnr)
    send_selected_to_qf(prompt_bufnr, "a", "loclist")
  end,
}
--- Sends all entries to the location list, replacing the previous entries.
---@param prompt_bufnr number: The prompt bufnr
actions.send_to_loclist = {
  pre = append_to_history,
  action = function(prompt_bufnr)
    send_all_to_qf(prompt_bufnr, " ", "loclist")
  end,
}
--- Adds all entries to the location list, keeping the previous entries.
---@param prompt_bufnr number: The prompt bufnr
actions.add_to_loclist = {
  pre = append_to_history,
  action = function(prompt_bufnr)
    send_all_to_qf(prompt_bufnr, "a", "loclist")
  end,
}

local smart_send = function(prompt_bufnr, mode, target)
  local picker = action_state.get_current_picker(prompt_bufnr)
  if #picker:get_multi_selection() > 0 then
    send_selected_to_qf(prompt_bufnr, mode, target)
  else
    send_all_to_qf(prompt_bufnr, mode, target)
  end
end

--- Sends the selected entries to the quickfix list, replacing the previous entries.
--- If no entry was selected, sends all entries.
---@param prompt_bufnr number: The prompt bufnr
actions.smart_send_to_qflist = {
  pre = append_to_history,
  action = function(prompt_bufnr)
    smart_send(prompt_bufnr, " ")
  end,
}
--- Adds the selected entries to the quickfix list, keeping the previous entries.
--- If no entry was selected, adds all entries.
---@param prompt_bufnr number: The prompt bufnr
actions.smart_add_to_qflist = {
  pre = append_to_history,
  action = function(prompt_bufnr)
    smart_send(prompt_bufnr, "a")
  end,
}
--- Sends the selected entries to the location list, replacing the previous entries.
--- If no entry was selected, sends all entries.
---@param prompt_bufnr number: The prompt bufnr
actions.smart_send_to_loclist = {
  pre = append_to_history,
  action = function(prompt_bufnr)
    smart_send(prompt_bufnr, " ", "loclist")
  end,
}
--- Adds the selected entries to the location list, keeping the previous entries.
--- If no entry was selected, adds all entries.
---@param prompt_bufnr number: The prompt bufnr
actions.smart_add_to_loclist = {
  pre = append_to_history,
  action = function(prompt_bufnr)
    smart_send(prompt_bufnr, "a", "loclist")
  end,
}
--- Open completion menu containing the tags which can be used to filter the results in a faster way
---@param prompt_bufnr number: The prompt bufnr
actions.complete_tag = function(prompt_bufnr)
  local current_picker = action_state.get_current_picker(prompt_bufnr)
  local tags = current_picker.sorter.tags
  local delimiter = current_picker.sorter._delimiter

  if not tags then
    utils.notify("actions.complete_tag", {
      msg = "No tag pre-filtering set for this picker",
      level = "ERROR",
    })

    return
  end

  -- format tags to match filter_function
  local prefilter_tags = {}
  for tag, _ in pairs(tags) do
    table.insert(prefilter_tags, string.format("%s%s%s ", delimiter, tag:lower(), delimiter))
  end

  local line = action_state.get_current_line()
  local filtered_tags = {}
  -- retrigger completion with already selected tag anew
  -- trim and add space since we can match [[:pattern: ]]  with or without space at the end
  if vim.tbl_contains(prefilter_tags, vim.trim(line) .. " ") then
    filtered_tags = prefilter_tags
  else
    -- match tag by substring
    for _, tag in pairs(prefilter_tags) do
      local start, _ = tag:find(line)
      if start then
        table.insert(filtered_tags, tag)
      end
    end
  end

  if vim.tbl_isempty(filtered_tags) then
    utils.notify("complete_tag", {
      msg = "No matches found",
      level = "INFO",
    })
    return
  end

  -- incremental completion by substituting string starting from col - #line byte offset
  local col = api.nvim_win_get_cursor(0)[2] + 1
  vim.fn.complete(col - #line, filtered_tags)
end

--- Cycle to the next search prompt in the history
---@param prompt_bufnr number: The prompt bufnr
actions.cycle_history_next = function(prompt_bufnr)
  local history = action_state.get_current_history()
  local current_picker = action_state.get_current_picker(prompt_bufnr)
  local line = action_state.get_current_line()

  local entry = history:get_next(line, current_picker)
  if entry == false then
    return
  end

  current_picker:reset_prompt()
  if entry ~= nil then
    current_picker:set_prompt(entry)
  end
end

--- Cycle to the previous search prompt in the history
---@param prompt_bufnr number: The prompt bufnr
actions.cycle_history_prev = function(prompt_bufnr)
  local history = action_state.get_current_history()
  local current_picker = action_state.get_current_picker(prompt_bufnr)
  local line = action_state.get_current_line()

  local entry = history:get_prev(line, current_picker)
  if entry == false then
    return
  end
  if entry ~= nil then
    current_picker:reset_prompt()
    current_picker:set_prompt(entry)
  end
end

--- Open the quickfix list. It makes sense to use this in combination with one of the send_to_qflist actions
--- `actions.smart_send_to_qflist + actions.open_qflist`
---@param prompt_bufnr number: The prompt bufnr
actions.open_qflist = function(prompt_bufnr)
  vim.cmd [[botright copen]]
end

--- Open the location list. It makes sense to use this in combination with one of the send_to_loclist actions
--- `actions.smart_send_to_qflist + actions.open_qflist`
---@param prompt_bufnr number: The prompt bufnr
actions.open_loclist = function(prompt_bufnr)
  vim.cmd [[lopen]]
end

--- Delete the selected buffer or all the buffers selected using multi selection.
---@param prompt_bufnr number: The prompt bufnr
actions.delete_buffer = function(prompt_bufnr)
  local current_picker = action_state.get_current_picker(prompt_bufnr)

  current_picker:delete_selection(function(selection)
    local force = vim.bo[selection.bufnr].buftype == "terminal"
    local ok = pcall(api.nvim_buf_delete, selection.bufnr, { force = force })

    -- If the current buffer is deleted, switch to the previous buffer
    -- according to bdelete behavior
    if ok and selection.bufnr == current_picker.original_bufnr then
      if api.nvim_win_is_valid(current_picker.original_win_id) then
        local jumplist = vim.fn.getjumplist(current_picker.original_win_id)[1]
        for i = #jumplist, 1, -1 do
          if jumplist[i].bufnr ~= selection.bufnr and vim.fn.bufloaded(jumplist[i].bufnr) == 1 then
            api.nvim_win_set_buf(current_picker.original_win_id, jumplist[i].bufnr)
            current_picker.original_bufnr = jumplist[i].bufnr
            return ok
          end
        end

        -- no more valid buffers in jumplist, create an empty buffer
        local empty_buf = api.nvim_create_buf(true, true)
        api.nvim_win_set_buf(current_picker.original_win_id, empty_buf)
        current_picker.original_bufnr = empty_buf
        api.nvim_buf_delete(selection.bufnr, { force = true })
        return ok
      end

      -- window of the selected buffer got wiped, switch to first valid window
      local win_id = vim.fn.win_getid(1, current_picker.original_tabpage)
      current_picker.original_win_id = win_id
      current_picker.original_bufnr = api.nvim_win_get_buf(win_id)
    end
    return ok
  end)
end

--- Cycle to the next previewer if there is one available.<br>
--- This action is not mapped on default.
---@param prompt_bufnr number: The prompt bufnr
actions.cycle_previewers_next = function(prompt_bufnr)
  action_state.get_current_picker(prompt_bufnr):cycle_previewers(1)
end

--- Cycle to the previous previewer if there is one available.<br>
--- This action is not mapped on default.
---@param prompt_bufnr number: The prompt bufnr
actions.cycle_previewers_prev = function(prompt_bufnr)
  action_state.get_current_picker(prompt_bufnr):cycle_previewers(-1)
end

--- Removes the selected picker in |builtin.pickers|.<br>
--- This action is not mapped by default and only intended for |builtin.pickers|.
---@param prompt_bufnr number: The prompt bufnr
actions.remove_selected_picker = function(prompt_bufnr)
  local curr_picker = action_state.get_current_picker(prompt_bufnr)
  local curr_entry = action_state.get_selected_entry()
  local cached_pickers = state.get_global_key "cached_pickers"

  if not curr_entry then
    return
  end

  local selection_index, _ = utils.list_find(function(v)
    if curr_entry.value == v.value then
      return true
    end
    return false
  end, curr_picker.finder.results)

  curr_picker:delete_selection(function()
    table.remove(cached_pickers, selection_index)
  end)

  if #cached_pickers == 0 then
    actions.close(prompt_bufnr)
  end
end

--- Display the keymaps of registered actions similar to which-key.nvim.<br>
--- - Notes:
---   - The defaults can be overridden via |action_generate.which_key|.
---   - Mappings are categorized by origin (`default` | `user_global` |
---     `picker`) with distinct highlights. On overflow, lower-priority
---     categories are dropped first (configurable via `category_drop_order`).
---   - Key codes can be substituted for display via `key_labels` (exact
---     match) and `replace_keys` (Lua-pattern pairs).
---   - The popup re-aligns on `VimResized` by default; set `resize = false`
---     to disable.
---@param prompt_bufnr number: The prompt bufnr
actions.which_key = function(prompt_bufnr, opts)
  require("telescope.actions._which_key").run(prompt_bufnr, opts)
end

--- Move from a none fuzzy search to a fuzzy one<br>
--- This action is meant to be used in live_grep and lsp_dynamic_workspace_symbols
---@param prompt_bufnr number: The prompt bufnr
actions.to_fuzzy_refine = function(prompt_bufnr)
  local line = action_state.get_current_line()
  local opts = (function()
    local opts = {
      sorter = conf.generic_sorter {},
    }

    local title = action_state.get_current_picker(prompt_bufnr).prompt_title
    if title == "Live Grep" then
      opts.prefix = "Find Word"
    elseif title == "LSP Dynamic Workspace Symbols" then
      opts.prefix = "LSP Workspace Symbols"
      opts.sorter = conf.prefilter_sorter {
        tag = "symbol_type",
        sorter = opts.sorter,
      }
    else
      opts.prefix = "Fuzzy over"
    end

    return opts
  end)()

  require("telescope.actions.generate").refine(prompt_bufnr, {
    prompt_title = string.format("%s (%s)", opts.prefix, line),
    sorter = opts.sorter,
  })
end

--- Delete the selected mark or all the marks selected using multi selection.
---@param prompt_bufnr number: The prompt bufnr
actions.delete_mark = function(prompt_bufnr)
  local current_picker = action_state.get_current_picker(prompt_bufnr)
  current_picker:delete_selection(function(selection)
    local bufname = selection.filename
    local bufnr = vim.fn.bufnr(bufname)
    local mark = selection.ordinal:sub(1, 1)

    local success
    if mark:match "%u" then
      success = pcall(api.nvim_del_mark, mark)
    else
      success = pcall(api.nvim_buf_del_mark, bufnr, mark)
    end
    return success
  end)
end

--- Insert the word under the cursor of the original (pre-Telescope) window
---@param prompt_bufnr number: The prompt bufnr
actions.insert_original_cword = function(prompt_bufnr)
  local current_picker = action_state.get_current_picker(prompt_bufnr)
  current_picker:set_prompt(current_picker.original_cword, false)
end

--- Insert the WORD under the cursor of the original (pre-Telescope) window
---@param prompt_bufnr number: The prompt bufnr
actions.insert_original_cWORD = function(prompt_bufnr)
  local current_picker = action_state.get_current_picker(prompt_bufnr)
  current_picker:set_prompt(current_picker.original_cWORD, false)
end

--- Insert the file under the cursor of the original (pre-Telescope) window
---@param prompt_bufnr number: The prompt bufnr
actions.insert_original_cfile = function(prompt_bufnr)
  local current_picker = action_state.get_current_picker(prompt_bufnr)
  current_picker:set_prompt(current_picker.original_cfile, false)
end

--- Insert the line under the cursor of the original (pre-Telescope) window
---@param prompt_bufnr number: The prompt bufnr
actions.insert_original_cline = function(prompt_bufnr)
  local current_picker = action_state.get_current_picker(prompt_bufnr)
  current_picker:set_prompt(current_picker.original_cline, false)
end

actions.nop = function(_) end

actions.mouse_click = function(prompt_bufnr)
  local picker = action_state.get_current_picker(prompt_bufnr)

  local pos = vim.fn.getmousepos()
  if pos.winid == picker.results_win then
    vim.schedule(function()
      picker:set_selection(pos.line - 1)
    end)
  elseif pos.winid == picker.preview_win then
    vim.schedule(function()
      actions.select_default(prompt_bufnr)
    end)
  end
  return ""
end

actions.double_mouse_click = function(prompt_bufnr)
  local picker = action_state.get_current_picker(prompt_bufnr)

  local pos = vim.fn.getmousepos()
  if pos.winid == picker.results_win then
    vim.schedule(function()
      picker:set_selection(pos.line - 1)
      actions.select_default(prompt_bufnr)
    end)
  end
  return ""
end

-- ==================================================
-- Transforms modules and sets the correct metatables.
-- ==================================================
actions = transform_mod(actions)
return actions
