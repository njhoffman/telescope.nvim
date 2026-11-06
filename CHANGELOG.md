# Changelog

Changes in this fork of telescope.nvim. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and versions follow
[Semantic Versioning](https://semver.org/). Tags up to v0.2.2 are upstream's; v0.3.0 is the first
fork release, so see upstream for earlier history.

## [Unreleased]

## [0.10.1] - 2026-11-05

### Fixed

- The selection and caret appear while results are still streaming, so `<CR>` works during a long search instead of only
  after it finishes. Moving the selection during a search keeps it there until the search finishes. From upstream PR
  #3690, with changes.
- `get_substr_matcher` no longer errors on a nil entry. From upstream PR #3691.

## [0.10.0] - 2026-11-05

### Removed

- `timestamp`, `cwd` and `project` from `cache_picker`. Nothing read them, and telescope no longer loads project.nvim.
- Files describing upstream's project: `.github/FUNDING.yml`, `.github/ISSUE_TEMPLATE/config.yml`,
  `.github/dependabot.yml`, `telescope.nvim-scm-1.rockspec` and the README's LuaRocks badge.

## [0.9.2] - 2026-11-05

### Fixed

- README states the tested minimum, Neovim v0.11.0.

## [0.9.1] - 2026-11-05

### Added

- The which_key options appear under `action_generate.which_key` in `:help telescope`.

### Changed

- CI tests the minimum Neovim, v0.11.0, checks generated docs on pushes to master, and lints specs too.
- Test setup looks for nvim-web-devicons at `../nvim-web-devicons`, so the devicons test can run.

### Fixed

- The center layout's `results_height` no longer pushes windows off the screen when larger than the room available.

## [0.9.0] - 2026-11-05

### Added

- Extension exports tell their picker which export opened it, through `opts.__name` and `picker.__name`.

### Fixed

- An extension's `setup` runs once, not again on first use after `load_extension`.
- The extension config is copied, so later changes to the caller's table don't affect it.

## [0.8.1] - 2026-11-05

### Fixed

- Removed an unused variable from the oneshot finder, which failed the lint check.

## [0.8.0] - 2026-11-05

### Changed

- `themes.get_minimal` with the vertical layout defaults to `mirror = true` and a 30-line height cap,
  so its windows share borders and results get more than one row.
- `enable_timing` output goes only to the log file, not `:messages`. Use
  `require("telescope.log").timing.level` to set its level. A replaced `telescope.log` without
  `timing` is used as is.

### Fixed

- which_key popup uses highlight groups that exist, so picker-specific keys get their emphasis.
- Oldfiles keeps protocol paths intact on Windows.
- Diagnostics picker no longer depends on a Neovim version check that would misfire on 1.0.
- Timing docs give the real log location.

## [0.7.7] - 2026-11-05

### Added

- README section describing what this fork adds.
- `PLENARY_DIR` to point the test setup at plenary.nvim when it is not at `../plenary.nvim`.

### Fixed

- `enable_timing` passed to oneshot pickers such as `find_files` reaches their finder.
- `themes.get_minimal` applies its layout again. Pickers had stopped storing `theme`, so its windows
  did not overlap and a stray `x` showed in the border.

### Removed

- The test setup no longer looks for plenary.nvim in a lazy.nvim install.

## [0.7.6] - 2026-11-05

### Changed

- `strip_path_prefix` only changes what is displayed and searched. Selecting an entry opens the full
  path, where it used to open the stripped path.

### Fixed

- Finder failures are logged with their `Finder failed with msg:` prefix.
- `enable_timing` passed to `live_grep` reaches its finder.
- `builtin.resume` keeps a picker's own `preview.debounce`.

### Removed

- Stray tracked files `.claude/session-summary.md` and `doc/specs/todo.md`.

## [0.7.5] - 2026-11-05

### Fixed

- Picker timers are closed when a picker closes, and smooth scrolling reuses one timer per picker
  instead of leaking a timer for each key press.
- Oneshot finder yields once per 1000 entries as intended, and whenever a pipe read needs to return
  to the main loop, instead of on every line.

## [0.7.4] - 2026-11-05

### Fixed

- `make test` no longer picks up the user's nvim config and plugins from the runtimepath.

## [0.7.3] - 2026-11-05

### Fixed

- which_key popup keeps the mappings that fit when a category overflows, instead of hiding the
  whole category. At 80x24 it showed no mappings at all.
- Git pickers honor an explicit `cwd` when the current buffer belongs to another repo.
- `use_file_path` on git pickers uses the repo root gitsigns detected, even with `use_git_root = false`.
- The last line of job output no longer ends in a literal newline when the command doesn't
  terminate it.

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
