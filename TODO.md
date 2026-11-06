# TODO

Issues and suggestions for this fork of telescope.nvim. Reviewed: 2026-11-05

Baseline at review: fork master `8c5b79f` (v0.7.7), level with upstream master `40aedd8`. About 80
inherited TODO/FIXME/HACK comments in `lua/` are upstream's and are not tracked here.

## 1. Bugs in fork code

- [x] **get_minimal only overlaps windows when mirrored in the vertical layout.** (p3) [bug] Its vertical borders assume an overlap that the default layout never applies.
      `lua/telescope/pickers/layout_strategies.lua` has `self.theme == "minimal"` only in the `mirror` branch of `vertical`.
      Probed at 200x60 with a preview: prompt row 34 and results row 31 at equal zindex, so nothing overlaps, and the 15-line
      cap leaves one results row. `themes.lua` puts a literal `x` in borders it expects to hide, so it likely shows.
      Fix: apply the offsets in the non-mirrored branch and relax the height cap, or drop vertical support.
- [x] **which_key links to highlight groups that don't exist.** (p3) [bug] `TelescopeResultsKeyword` and `TelescopePrompt` are undefined after setup.
      `lua/telescope/actions/_which_key/highlights.lua` links `TelescopeWhichKeyPickerBind` to the first and
      `TelescopeWhichKeyNormal` to the second, so picker-specific keys lose their intended emphasis unless a colorscheme
      defines them. Fix: link to defined groups, such as `TelescopePromptNormal` for the window.
- [x] **enable_timing prints into the message area.** (p3) [bug] Info-level lines go to `:messages` as well as the log file.
      `lua/telescope/log.lua` keeps plenary's default console output. Confirmed with `log.info`: each picker adds at least
      four lines (start, input ready, completed, close), which clutters normal use while profiling. Fix: log the timing
      lines to the file only, for example with a dedicated logger using `use_console = false`.
- [x] **Oldfiles rewrites slashes in protocol paths on Windows.** (p3) [bug] The session-buffer loop computes `protocol` but converts anyway.
      `lua/telescope/builtin/__internal.lua:566` turns `oil://x` into `oil:\\x`. `has_protocol` also uses `[A-z0-9]`, which
      matches `[ \ ] ^ _` and a backtick. Found by reading; not run on Windows. Fix: skip the conversion for protocol paths and use
      `%a[%w+.-]*://`.
- [x] **Remove the Neovim version check in the diagnostics picker.** (p3) [bug] `vim.version().minor > 9` is obsolete and would misfire on Neovim 1.0.
      `lua/telescope/builtin/__diagnostics.lua:89`: with minor 0, an empty severity table would no longer be cleared.
      Upstream has the same line, and the 0.11 minimum makes the check unnecessary.

- [x] **The nvim config shadowed two fork modules.** (p2) [bug] Changes to these files didn't take effect in the real setup, and specs here couldn't see it.
      `~/.config/nvim` comes first on the runtimepath, so its `lua/telescope/log.lua` and `lua/telescope/_extensions/init.lua`
      replaced the fork's. The extension features moved into the fork, and the config now configures `telescope.log` at setup.
      `tests/unit/telescope_shadow_spec.lua` in the config fails if a shadow comes back.

## 2. Tests and CI

- [x] **Resolve the three pending tests.** (p3) [test] They are skipped, not passing, and all are inherited.
      `action_spec.lua:491` (select and edit compatibility) and `telescope_spec.lua:98` (fuzzy_file ordering) have no
      implementation decision recorded. `find_files_spec.lua:53` (devicons) can't run as written: CI clones
      `../nvim-web-devicons`, but `minimal_init.vim` never adds it to the runtimepath. Implement or delete each.
- [x] **Add specs for the remaining fork options.** (p3) [test] Grep of `lua/tests` finds no coverage for them.
      Missing: `scroll_previewer_by` and `scroll_previewer_page` without animation, and the center layout's `results_height`,
      including a value larger than the available height. Oldfiles has no specs either, which matters for the Windows bug.
- [x] **Test the minimum Neovim version.** (p3) [test] The CI matrix runs only stable and nightly, while `plugin/telescope.lua` accepts any 0.11.
      Nothing checks the floor once stable moves past it. The README says `>=v0.11.7` and links to v0.11.6, which is inherited.
      Fix: add a pinned 0.11 to `ci.yml` and make the README and the check agree.
- [x] **Check docs on push.** (p3) [chore] `docgen.yml` runs only on pull requests, and this fork pushes straight to master.
      `make docgen` is clean today, but only because it was run by hand. Fix: add `push: branches: [master]`.
- [x] **Extend luacheck to the specs.** (p3) [chore] `make lint` covers `lua/telescope` only, and `lua/tests` has 6 warnings.
      `luacheck lua/tests` reports 4 W211 and 2 W111. Fix them and lint both paths, keeping any test globals in `.luacheckrc`.

## 3. Docs and cleanup

- [x] **Correct the documented log path.** (p2) [docs] Following the docs leads to a file that isn't being written.
      `TIMING_DIAGNOSTICS.md:141` and `CLAUDE.md:254` say `~/.cache/nvim/telescope.log`. On the local Neovim 0.13-dev it is
      `~/.local/state/nvim/logs/telescope.log`, and an orphaned 1.7 MB copy sits at `~/.local/state/nvim/telescope.log`.
      Fix: document `:echo stdpath("log")`. The `level = 'info'` advice is also the default, and detail needs `'debug'`.
- [x] **Update stale sections of CLAUDE.md.** (p3) [docs] Several parts predate the upstream merge.
      Docgen commands (lines 36-40) still describe tree-sitter-lua, while `make docgen` now uses docgen.nvim from `.deps`. Lines
      153 and 207 require tree-sitter annotations, and line 199 calls `0.1.x` the recommended branch. The timing file list
      omits `finders/timing.lua`, as does `TIMING_DIAGNOSTICS.md`. The custom features section covers timing only.
- [x] **Render the which_key options in the vimdoc.** (p3) [docs] The README sends readers to `:help telescope`, but these options aren't there.
      `lua/telescope/actions/generate.lua` documents them in `telescope.actions.generate.which_key.opts`, while the function
      declares `@param opts table`, so docgen skips them, upstream's included. Fix: reference the class from `@param`.
      The 0.7.2 changelog line about restoring the which_key options overstated this; only the notes on `actions.which_key` came back.
- [ ] **Decide whether cached pickers need project fields.** (p3) [refactor] `timestamp`, `cwd` and `project` are written but never read.
      `lua/telescope/pickers.lua:1764` sets them on every close, and nothing here or in the nvim config uses them, yet
      `project` is the only reason telescope touches project.nvim. Fix: remove them, or use them in a picker of cached pickers.
- [ ] **Review inherited project files.** (p3) [chore] Several still describe upstream's project rather than this fork.
      `.github/FUNDING.yml`, `.github/ISSUE_TEMPLATE/config.yml`, `.github/dependabot.yml`, the README LuaRocks badge, and
      `telescope.nvim-scm-1.rockspec`, which nothing publishes since the release workflow was removed.
- [x] **Remove leftover local refs.** (p3) [chore] Neither is needed now.
      The `sync-upstream` branch is fully merged into master. The `minimal-theme` remote only served the theme port.

## 4. Upstream

- [ ] **Offer the oneshot yield fix upstream.** (p3) [chore] Upstream's read loop has the same always-true check.
      `async_oneshot_finder.lua` upstream has `if num_results % await_count then`. The fix here needs `vim.in_fast_event()`
      too, and the description should say it is a correctness cleanup with no measurable speedup in a real picker. Opening a
      PR is public, so it is your call.
- [ ] **Watch open upstream PRs.** (p3) [chore] Upstream has no new commits since `40aedd8`. Diffs of these six were read on 2026-11-05; none applied.
      Worth taking if upstream stalls: #3691 (one line, nil entry guard in `get_substr_matcher`) and #3690 (selection caret
      and `<CR>` while results stream; add its throttle timer to `self.timers`, which the PR doesn't do, or it leaks).
      Only if hit: #3686 (prefilter tags with whitespace), #3697 (previews for custom URI schemes).
      Skip: #3682 (replaces `fnameescape` with `bufadd`, wraps edits in `pcall` that hides errors, its author asks for careful
      review) and #3694 (`get_ref` increments the counter, which looks like a bug).

## Completed

### 1. Bugs in fork code (completed 2026-11-05)

- [x] **Closing a picker errors when project.nvim is not installed.** (p1) [bug] `on_close_prompt` requires `project_nvim` unguarded.
      `lua/telescope/pickers.lua:1761` calls `require("project_nvim").get_project_root()`, and the default
      `cache_picker` config reaches it on every close. Reproduced headless with the module unavailable:
      `actions.close` raises and the picker windows stay open. Fix: `pcall(require, ...)` and leave
      `cache_picker.project` nil when absent.
- [x] **Diagnostics picker breaks severity filtering.** (p1) [bug] `vim.diagnostic.get` is passed the severity instead of an opts table.
      `lua/telescope/builtin/__diagnostics.lua:121` passes `diagnosis_opts.severity`; upstream passes `diagnosis_opts`.
      Reproduced on the local nvim 0.13-dev: a number raises `opts: expected table, got number`, and `{ min = ERROR }`
      is ignored (returned 2 of 2 diagnostics, 1 expected), which covers `severity_limit` and `severity_bound`.
      Fix: pass `diagnosis_opts` and drop the NOTE comment; add a spec.
- [x] **Final line without a newline keeps a literal newline.** (p2) [bug] `LinesPipe:iter` returns `"b\n"` for the last line.
      `lua/telescope/async_job.lua:166` appends `"\n"` and the is-done branch returns it as is. Reproduced with
      `new_oneshot_job({ "printf", "a\\nb" })`, which yields `{ "a", "b\n" }`. Also wrong for NUL-split output.
      Fix: return `previous` unchanged. `elseif next_value ~= nil` at line 197 is always true, so its `else` is dead code.
- [x] **Gitsigns detection overrides an explicit cwd.** (p2) [bug] Git pickers follow the current buffer's repo even when told otherwise.
      `try_gitsigns` (`lua/telescope/builtin/__git.lua:443`) runs first in `set_opts_cwd` (line 490) and returns early, so
      `git_files({ cwd = "~/other" })` gets the buffer's repo root, gitdir and work tree; `use_file_path` is skipped too.
      Fixed for explicit `cwd` only: gitsigns reports the repo of the file itself, so `use_file_path` keeps using it,
      which also keeps bare-repo dotfiles working.
- [x] **Timers are stopped but never closed.** (p2) [bug] libuv handles leak for each picker and each smooth-scroll tap.
      `Picker:_detach` (`lua/telescope/pickers.lua:1831`) only stops `self.timers`, though `debounce.lua` says the caller
      must close them. `__smoothscroll_previewer` (`lua/telescope/actions/set.lua:336`) allocates a timer per tap and
      appends it to `picker.timers`. Found by reading the code. Fix: close with an `is_closing` guard, and reuse one
      timer per picker for smooth scrolling.
- [x] **Finder failure log loses its message prefix.** (p3) [bug] Operator precedence in the log call.
      `lua/telescope/pickers.lua:801` evaluates `"..." .. type(msg) == "string"` as false, so only `vim.inspect(msg)` is
      logged. The fork also raised this from upstream's `log.warn` to `log.error`. Fix: parenthesize the conditional.
- [x] **strip_path_prefix does more than its docs say.** (p3) [bug] Documented as a display option, but it rewrites the path used to open the file.
      `lua/telescope/make_entry.lua:488` changes `filename`, which feeds `entry.filename` and `ordinal`, and only
      Now display and search text only: `entry.filename` keeps the full path, so selecting opens the right file. Other
      entry makers still don't apply it.
- [x] **Per-picker enable_timing misses live_grep.** (p3) [bug] `finders.new_job` does not forward the option.
      `lua/telescope/finders.lua` builds `async_job_finder` from three fixed fields, so job-based pickers only honor the
      global setting, while `TIMING_DIAGNOSTICS.md` documents per-picker use. The "Pass through enable_timing" comment in
      `new_async_job` has no code behind it.
- [x] **Resume drops per-picker preview.debounce.** (p3) [bug] Only the global setting survives `builtin.resume`.
      Reproduced: a picker made with `{ preview = { debounce = 20 } }` has no `_preview_refresh_debounced` after resume.
      Fix: keep the value on the picker and read it in `Picker:new`.

- [x] **which_key shows no mappings when one category overflows.** (p2) [bug] Truncation drops whole categories instead of trimming them.
      `M.truncate` in `lua/telescope/actions/_which_key/layout.lua` empties `default` whenever the total exceeds capacity.
      Reproduced at 80x24: 28 default mappings, room for 9, and the popup shows only `... +28 more`. Fix: stop dropping
      once the remainder fits and clip the last category; `which_key_spec` truncate cases may need updating.

### 2. Upstream sync (completed 2026-11-05)

- [x] **Regenerate doc/telescope.txt after the merge.** (p1) [docs] The vimdoc lacks fork entries, and the "Check docs" workflow will fail until it is regenerated.
      `make docgen` clones `jamestrew/docgen.nvim` v1.1.0 into `.deps` and runs it, which was blocked by a permission check
      during the merge, so the 19 doc conflicts took upstream's side. Missing: `get_minimal`, `scroll_previewer_by`,
      `smoothscroll_previewer_by`, `category_drop_order`, `results_height`. `gendocs.lua` expects plenary at
      `../plenary.nvim`. Fork comments such as `get_minimal` may need upstream's annotation style.

- [x] **Merge the 29 upstream commits.** (p1) [chore] The last upstream merge was March 2026 and a dry run conflicts in 11 files.
      `git merge-tree` conflicts: `doc/telescope.txt`, `actions/generate.lua`, `actions/init.lua`, `builtin/__git.lua`,
      `config.lua`, `finders/async_job_finder.lua`, `finders/async_oneshot_finder.lua`, `make_entry.lua`, `pickers.lua`,
      `pickers/layout_strategies.lua`, `scripts/minimal_init.vim`. Regenerate the doc rather than resolving its 18 hunks.
      Do the formatting item below first.
- [x] **Restore upstream formatting before merging.** (p2) [refactor] Style churn adds conflicts and hides the fork's real changes.
      `.stylua.toml` sets `call_parentheses = "Always"` (upstream `"None"`), and parts of `layout_strategies.lua` wrap near
      100 columns against a configured 120. Measured in a scratch clone with all three sides normalized to upstream's
      config: code conflict hunks drop from 23 to 12, files from 11 to 9, `layout_strategies.lua` from 10 hunks to 1.
- [x] **Decide on upstream's Neovim 0.11 minimum.** (p2) [chore] `e6cdb4d` requires 0.11 and drops the compat shims; the fork declares 0.10.4.
      Adopting it removes `utils.nvim011` and the shims in `utils.lua`, `debounce.lua` and `__lsp.lua`. Touches
      `plugin/telescope.lua`, the README and the CI matrix. Local nvim is 0.13-dev, so adopting looks low risk here.
- [x] **Plan for breaking upstream changes.** (p2) [refactor] Several need follow-up beyond conflict resolution.
      `f7c673b` renames `lua/telescope/_.lua` to `async_job.lua`, which holds the fork's `LinesPipe` change and is required
      by both finders. `aa4ad82` stubs `vim.F` across 22 files, and fork-only modules (`actions/_which_key/`, finders) need
      the same treatment. `d49d056`, `cb1a129` and `3ab376c` replace the docgen tool used by `scripts/gendocs.lua`.
      `8eb2d60` switches `dynamic_workspace_symbols` to `generic_sorter`.
- [x] **Take upstream's fixes.** (p2) [bug] Worth cherry-picking if the full merge is delayed.
      `073c000` grep_string `|` escaping; `a8bc00e` tags entry order; `e3f333b` quickfix list nr; `9377230` diagnostic code
      field (with spec); `be6a84e`, `f04ab73`, `5063384` previewer line splitting, timeouts and trailing blank line;
      `62cc799` no folding in TelescopeResults.
- [x] **Adopt upstream's new options.** (p3) [feature] Arrive with the merge; document any that overlap fork features.
      `48d2656` show_line for live_grep and grep_string; `796ee6e` hidden-file toggle for grep pickers; `43ba8c2` buffers
      `disable_coordinates`; `028d9a0` workspace/diagnostic option.
- [x] **Finish upstream's oneshot yield fix.** (p2) [perf] `40aedd8` fixed only the replay loop; the job read loop still yielded on every line.
      Fixed with `vim.in_fast_event() or num_results % await_count == 0`. A plain `== 0` is wrong: after a pipe read the
      loop resumes in a fast event, and entry makers calling the API fail with E5560. Yields drop from 200000 to 224 for
      200k lines, but a real picker shows no measurable change in load time or longest stall (about 1s and 100ms either
      way). Upstream's copy has the same line, so this could be offered upstream as a correctness cleanup.
- [x] **Avoid tag collisions with upstream.** (p3) [chore] Fork tags v0.3.0 to v0.4.0 use the same scheme as upstream, whose latest is v0.2.2.
      An upstream v0.3.0 would collide on fetch. Options: a fork suffix or prefix, or `--no-tags` on the upstream remote.

### 3. Tests and CI (completed 2026-11-05)

- [x] **`make test` fails on gitops specs.** (p1) [test] Three specs test a module that is not in this repo.
      `lua/tests/automated/gitops_{exports,entry,utils}_spec.lua` require `gitops.*`, which lives in
      `~/.config/nvim/lua/modules/gitops`. Local run on `cce6200`: 276 passed and 0 failed in the other specs, 5 errors in
      `gitops_exports_spec`, and `gitops_entry` and `gitops_utils` report no results, so `make test` exits 1. Fix: move the
      specs next to the module. `which_key_spec` should be unaffected.
- [x] **Tests are not isolated from the personal nvim config.** (p2) [test] `-u scripts/minimal_init.vim` left `~/.config/nvim` on the runtimepath.
      `runtime! plugin/telescope.lua` also ran the config's copy, and `project_nvim` resolved from `~/.config/nvim/lua`,
      which hid the close bug locally. `minimal_init.vim` now removes the config and data dirs and clears `packpath`;
      `test_isolation_spec` guards it. `PlenaryBustedFile` ignores `-u` and loads the full config, so run single specs
      with `PlenaryBustedDirectory` (see `CLAUDE.md`).
- [x] **CI is red on master.** (p2) [chore] The latest runs (2026-10-20) fail on every leg of Tests and on both lint jobs.
      Tests and stylua passed on `d0e6f8c`. Luacheck's last 6 W631 lines in `actions/generate.lua` are now exempt in
      `.luacheckrc`; confirm green on the next push.
- [x] **No specs for most fork features.** (p2) [test] Grep of `lua/tests` finds no coverage for them.
      Missing: `scroll_previewer_by`, `scroll_previewer_page`, smooth scrolling, `preview.debounce`, `enable_timing`,
      `strip_path_prefix`, `themes.get_minimal`, `LinesPipe` flushing, gitsigns detection. Start with the bugs in project 1,
      each of which should get a regression spec.
- [x] **Docgen workflow pins an unsupported Neovim.** (p2) [chore] `docgen.yml` installs 0.9.5, but `plugin/telescope.lua` requires 0.10.4.
      Replace it with upstream's simplified workflow as part of the merge, or update the pin.
- [x] **Release workflow runs on every fork tag.** (p3) [chore] `release.yml` uploads to LuaRocks on any tag push.
      This fork should not publish under upstream's rock. Remove it, or limit it to `workflow_dispatch`.

### 4. Docs and cleanup (completed 2026-11-05)

- [x] **Add a VERSION file.** (p2) [chore] Versions exist only as tags; the next commit should settle the source of truth.
      HEAD is 6 commits past v0.4.0 including `feat(which_key)`, so the next bump is minor (0.5.0).
- [x] **Document the fork's features.** (p3) [docs] README is upstream's and does not say how this fork differs.
      Add a short section linking `TIMING_DIAGNOSTICS.md` and covering preview scroll actions, `preview.debounce`, which_key
      categories, gitsigns detection, `get_minimal`, `scrolling_limit`, `strip_path_prefix`. State that project.nvim and
      gitsigns are optional.
- [x] **Fix the version in CLAUDE.md.** (p3) [docs] It says Neovim v0.10.0+ while `plugin/telescope.lua` requires 0.10.4.
      Update together with the 0.11 decision in project 2.
- [x] **Remove stray tracked files.** (p3) [chore] Both are session notes rather than project files.
      `.claude/session-summary.md` is tracked although `.claude/` is ignored. `doc/specs/todo.md` is one URL with raw ANSI
      escapes, pointing at upstream PR 3540, which closed unmerged.
- [x] **Remove the machine-specific test path.** (p3) [chore] `scripts/minimal_init.vim` hardcodes a lazy.nvim plenary path.
      It is also one of the merge conflicts. Prefer a `PLENARY_DIR` environment override or a local symlink at
      `../plenary.nvim`.
- [x] **Share the timing helpers.** (p3) [refactor] `format_command` and `log_timing_stats` are duplicated in both job finders.
      Move them to one module, which also shrinks the fork's conflict surface in `finders/`.
