# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

telescope.nvim is a highly extendable fuzzy finder plugin for Neovim built on latest neovim core features. It provides a modular architecture for searching, filtering, and picking items through a unified interface.

**Core Requirements:**
- Neovim v0.9.0+ compiled with LuaJIT (not Lua 5.1)
- plenary.nvim dependency (required)
- ripgrep (for live_grep and grep_string)

## Development Commands

### Testing
```bash
# Run all automated tests
make test

# Tests use plenary.nvim's test harness and are located in lua/tests/automated/
# The test command runs: nvim --headless --noplugin -u scripts/minimal_init.vim -c "PlenaryBustedDirectory lua/tests/automated/ { minimal_init = './scripts/minimal_init.vim' }"
```

### Linting
```bash
# Lint Lua code with luacheck
make lint
```

### Documentation Generation
```bash
# Generate vim documentation from tree-sitter annotations
make docgen

# Runs: nvim --headless --noplugin -u scripts/minimal_init.vim -c "luafile ./scripts/gendocs.lua" -c 'qa'
# Documentation is generated from tree-sitter-lua annotations in the source code
```

## Architecture

### Component Flow
```
User Input (Prompt) → Finder → Entry Manager → Sorter → Results Display
                                    ↓
                              Previewer (shows context)
                                    ↓
                          Actions (on selection)
```

### Core Components

**Picker** (`lua/telescope/pickers.lua`)
- Central UI component managing the telescope window layout
- Coordinates between finder, sorter, previewer, and results display
- Creates three windows: prompt, results, and preview
- Entry point: `pickers.new(opts, picker_opts):find()`

**Finder** (`lua/telescope/finders.lua`)
- Generates results to pick from (files, grep output, LSP symbols, etc.)
- Types: `new_table` (static), `new_job` (async process), `new_oneshot_job`, `new_async_job`
- Returns raw "value" data that gets processed by entry_maker

**Entry Manager** (`lua/telescope/entry_manager.lua`)
- Manages collection of entries from finder
- Handles sorting and filtering
- Coordinates with sorter to order results

**Sorter** (`lua/telescope/sorters.lua`)
- Scores entries based on prompt input
- Returns "distance" number (lower = better match)
- Default sorters: `get_fuzzy_file`, `get_generic_fuzzy_sorter`

**Previewer** (`lua/telescope/previewers/`)
- Shows context for selected entry
- Types: `vim_buffer_*` (default, uses vim buffers), `cat/vimgrep/qflist` (terminal-based)
- Buffer previewers use tree-sitter for syntax highlighting

**Actions** (`lua/telescope/actions/`)
- Functions that respond to user input (enter, tab, etc.)
- Access picker state via `require('telescope.actions.state')`
- Custom actions: use `require('telescope.actions.mt').transform_mod`

**Layout Strategies** (`lua/telescope/pickers/layout_strategies.lua`)
- Determine window positioning: `horizontal`, `vertical`, `center`, `cursor`, `bottom_pane`, `flex`
- Configurable via `layout_strategy` and `layout_config` options

**Themes** (`lua/telescope/themes.lua`)
- Predefined style combinations: `get_dropdown`, `get_cursor`, `get_ivy`
- Combine layout, borders, sizing, and other UI elements

### Directory Structure

```
lua/telescope/
├── builtin/              # Built-in pickers (find_files, live_grep, LSP, git, etc.)
│   ├── __files.lua
│   ├── __git.lua
│   ├── __lsp.lua
│   └── __diagnostics.lua
├── pickers/              # Picker implementation and UI components
│   ├── layout_strategies.lua
│   ├── layout.lua
│   ├── window.lua
│   └── entry_display.lua
├── previewers/           # Preview implementations
├── actions/              # User actions and state management
├── finders.lua           # Finder constructors
├── sorters.lua           # Sorting algorithms
├── config.lua            # Configuration management
├── themes.lua            # Theme definitions
└── _extensions/          # Extension system
```

## Configuration System

Telescope uses a three-tier configuration hierarchy:

1. **defaults**: Global settings for all pickers
2. **pickers**: Per-picker defaults (e.g., `find_files = {...}`)
3. **extensions**: Third-party extension settings

Configuration is set via `require('telescope').setup({...})` and resolved through `lua/telescope/config.lua`.

## Entry Maker Pattern

Entry makers transform raw finder results into structured entries:

```lua
entry = {
  value = <raw_result>,        -- Original data from finder
  ordinal = <search_string>,   -- String used for sorting/filtering
  display = <display_string>,  -- How entry appears in results
  -- Optional: filename, lnum, col, etc. for actions
}
```

## Extension System

Extensions live in separate repos and are loaded via:
```lua
require('telescope').load_extension('extension_name')
require('telescope').extensions.extension_name.picker()
```

Extensions register themselves via `telescope.register_extension(module)`.

## Documentation Standards

- Use tree-sitter-lua annotations for all public functions
- Module exports (functions in returned table) are auto-documented
- Private functions (prefixed with `__` or local) are not exported
- See CONTRIBUTING.md for detailed documentation guide
- Annotations: `---@tag`, `---@brief`, `---@param`, `---@return`, etc.

## Important Patterns

### Creating a Picker
```lua
local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values

pickers.new(opts, {
  prompt_title = 'My Picker',
  finder = finders.new_table { results = {...} },
  sorter = conf.generic_sorter(opts),
  attach_mappings = function(prompt_bufnr, map)
    -- Custom key mappings
    return true  -- Keep default mappings
  end,
}):find()
```

### Custom Actions
```lua
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')

local my_action = function(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  actions.close(prompt_bufnr)
  -- Do something with selection
end
```

### Layout Configuration
Use "resolvable" sizes:
- Decimal (0-1): percentage of available space
- Integer (>1): absolute character/line count
- Function: `function(picker, max_columns, max_lines) return number end`

## Git Workflow

- Main branch: `master`
- Release branch: `0.1.x` (recommended for users)
- Not recommended to run latest master in production

## Contributing Notes

From CONTRIBUTING.md:
- **Not accepting new builtin pickers** - create extensions instead
- Bug fixes, documentation improvements, and non-picker features welcome
- Must use tree-sitter documentation annotations
- CI auto-generates documentation on PRs

## Testing Approach

- Tests use plenary.nvim test harness
- Located in `lua/tests/automated/`
- Some interactive test cases in `lua/tests/pickers/`
- Requires minimal_init.vim setup with plenary.nvim and tree-sitter-lua

## Key Files for Common Tasks

- Adding new sorter: `lua/telescope/sorters.lua`
- Adding new previewer: `lua/telescope/previewers/`
- Modifying layout: `lua/telescope/pickers/layout_strategies.lua`
- Adding default action: `lua/telescope/actions/init.lua`
- Changing default config: `lua/telescope/config.lua`
- Modifying window creation: `lua/telescope/pickers/window.lua`

## Custom Features in This Fork

### Timing Diagnostics

This fork includes comprehensive timing diagnostics for profiling picker and finder performance. See `TIMING_DIAGNOSTICS.md` for full documentation.

**Quick Start:**
```lua
require('telescope').setup({
  defaults = {
    enable_timing = true,  -- Enable global timing diagnostics
  },
})
```

**Features:**
- Logs external command execution with full arguments
- Tracks data loading performance (entries/sec, time to first entry)
- Measures UI responsiveness (layout creation, time until interactive)
- Records result display latency

**Modified Files:**
- `lua/telescope/finders/async_job_finder.lua` - Command execution timing
- `lua/telescope/finders/async_oneshot_finder.lua` - Oneshot job timing
- `lua/telescope/pickers.lua` - UI responsiveness metrics
- `lua/telescope/config.lua` - Configuration option

**Log Location:**
- Linux/macOS: `~/.cache/nvim/telescope.log`
- Windows: `~/AppData/Local/nvim-data/telescope.log`

Set log level: `require('telescope.log').level = 'info'`
