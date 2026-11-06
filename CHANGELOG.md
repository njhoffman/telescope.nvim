# Changelog

Changes in this fork of telescope.nvim. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and versions follow
[Semantic Versioning](https://semver.org/). Tags up to v0.2.2 are upstream's; v0.3.0 is the first
fork release, so see upstream for earlier history.

## [Unreleased]

## [0.7.2] - 2026-11-05

### Fixed

- `doc/telescope.txt` regenerated with upstream's docgen, restoring the fork's entries such as
  `themes.get_minimal`, the previewer scroll actions and the which_key options.

## [0.7.1] - 2026-11-05

### Removed

- LuaRocks release workflow, so pushing a fork tag no longer tries to publish a rock.

## [0.7.0] - 2026-11-05

Merged upstream telescope.nvim through `40aedd8`.

### Added

- `show_line` option for `live_grep` and `grep_string`.
- Hidden-file toggle for `live_grep` and `grep_string`.
- `disable_coordinates` option for `buffers`.
- Option to use workspace/diagnostic in the diagnostics picker.

### Changed

- **Breaking:** `lua/telescope/_.lua` is now `telescope.async_job`, so `require("telescope._")` no longer works.
- **Breaking:** `lsp_dynamic_workspace_symbols` uses the generic sorter.
- `doc/telescope.txt` uses upstream's new format and is missing some fork entries until it is regenerated.

### Fixed

- `grep_string` escapes `|` in the pattern.
- Tags entries show their fields in the right order.
- Quickfix actions default to the current list instead of the last one.
- Diagnostic entries keep their `code` field.
- Previewer line splitting, timeouts and trailing blank line.
- No folding in the results window.
- Oneshot finder no longer yields on every entry when replaying results.

## [0.6.0] - 2026-11-05

### Changed

- **Breaking:** Neovim 0.11 is now the minimum, matching upstream. Compatibility shims for 0.10 are gone,
  including `utils.hl_range`, `utils.str_byteindex`, `utils.validate` and `utils.has_ts_parser`.

### Removed

- **Breaking:** `results_ts_highlight` option. Treesitter highlighting is used whenever a parser is available.

## [0.5.1] - 2026-11-05

### Changed

- Lua sources follow upstream's stylua settings again, which keeps upstream merges smaller. No
  behavior changes.

## [0.5.0] - 2026-11-05

### Added

- `TODO.md`, `VERSION` and this changelog.
- which_key popup groups and highlights mappings by origin (default, user, picker), drops lower
  priority categories first when space runs out, reflows on editor resize, and supports key label
  substitution through `key_labels` and `replace_keys`.
- Keymap descriptions carry their origin in the prefix, for example `telescope:picker|name`.

### Changed

- Replaced deprecated Neovim APIs.

### Fixed

- Highlights previewer no longer errors when its window has gone away.
- Closing a picker no longer errors and leaves its windows open when project.nvim is not installed.
- Diagnostics picker honors `severity`, `severity_limit`, `severity_bound` and `namespace` again.

### Removed

- gitops specs, which test a module in the nvim config and now live there. `make test` no longer
  depends on that module.

## [0.4.0] - 2026-04-15

### Added

- Preview actions for scrolling by line and by page, with optional smooth scrolling.
- `preview.debounce` to coalesce preview refreshes while moving quickly through results.
- Git pickers use the repo gitsigns detected for the current buffer, which supports bare-repo
  dotfiles, and git actions honor that repo.
- Log output for async job finders.

### Fixed

- Preview close and timing bookkeeping stay consistent when a picker closes.

## [0.3.1] - 2026-03-21

### Added

- `enable_timing` as a global `defaults` option, with the picker name in timing logs.

## [0.3.0] - 2026-03-16

First tagged fork release, merged with upstream and collecting the changes the fork had carried.

### Added

- Timing diagnostics for pickers and finders (see `TIMING_DIAGNOSTICS.md`).
- `strip_path_prefix` for quickfix-style entries.
- `scrolling_limit` option for the number of scrollable results.
- `themes.get_minimal`.
- Cached pickers record timestamp, cwd and project root.
- Oldfiles keeps entries with a protocol path such as `oil://`.

### Changed

- Minimum Neovim raised to 0.10.

### Fixed

- Checks for stale windows when reading the prompt.
- Test setup finds plenary in a lazy.nvim install.
