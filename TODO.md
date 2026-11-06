# TODO

Issues and suggestions for this fork of telescope.nvim. Reviewed: 2026-11-05

Baseline at review: fork master `cce6200`, upstream master `40aedd8`, 133 fork-only and 29
upstream-only commits, merge base `5255aa2` (upstream tag v0.2.2). About 80 inherited
TODO/FIXME/HACK comments in `lua/` are upstream's and are not tracked here.

## 1. Bugs in fork code

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
- [ ] **Final line without a newline keeps a literal newline.** (p2) [bug] `LinesPipe:iter` returns `"b\n"` for the last line.
      `lua/telescope/_.lua:166` appends `"\n"` and the is-done branch returns it as is. Reproduced with
      `new_oneshot_job({ "printf", "a\\nb" })`, which yields `{ "a", "b\n" }`. Also wrong for NUL-split output.
      Fix: return `previous` unchanged. `elseif next_value ~= nil` at line 197 is always true, so its `else` is dead code.
- [ ] **Gitsigns detection overrides an explicit cwd.** (p2) [bug] Git pickers follow the current buffer's repo even when told otherwise.
      `try_gitsigns` (`lua/telescope/builtin/__git.lua:443`) runs first in `set_opts_cwd` (line 490) and returns early, so
      `git_files({ cwd = "~/other" })` gets the buffer's repo root, gitdir and work tree; `use_file_path` is skipped too.
      Found by reading the code, not reproduced. Fix: only consult gitsigns when neither `opts.cwd` nor `use_file_path` is
      set. Keep the bare-repo dotfiles case working and add a spec.
- [ ] **Timers are stopped but never closed.** (p2) [bug] libuv handles leak for each picker and each smooth-scroll tap.
      `Picker:_detach` (`lua/telescope/pickers.lua:1831`) only stops `self.timers`, though `debounce.lua` says the caller
      must close them. `__smoothscroll_previewer` (`lua/telescope/actions/set.lua:336`) allocates a timer per tap and
      appends it to `picker.timers`. Found by reading the code. Fix: close with an `is_closing` guard, and reuse one
      timer per picker for smooth scrolling.
- [ ] **Finder failure log loses its message prefix.** (p3) [bug] Operator precedence in the log call.
      `lua/telescope/pickers.lua:801` evaluates `"..." .. type(msg) == "string"` as false, so only `vim.inspect(msg)` is
      logged. The fork also raised this from upstream's `log.warn` to `log.error`. Fix: parenthesize the conditional.
- [ ] **strip_path_prefix does more than its docs say.** (p3) [bug] Documented as a display option, but it rewrites the path used to open the file.
      `lua/telescope/make_entry.lua:488` changes `filename`, which feeds `entry.filename` and `ordinal`, and only
      `gen_from_quickfix` applies it. Stripping may be intended for container paths; decide, then either fix the docs
      or strip display only.
- [ ] **Per-picker enable_timing misses live_grep.** (p3) [bug] `finders.new_job` does not forward the option.
      `lua/telescope/finders.lua` builds `async_job_finder` from three fixed fields, so job-based pickers only honor the
      global setting, while `TIMING_DIAGNOSTICS.md` documents per-picker use. The "Pass through enable_timing" comment in
      `new_async_job` has no code behind it.
- [ ] **Resume drops per-picker preview.debounce.** (p3) [bug] Only the global setting survives `builtin.resume`.
      Reproduced: a picker made with `{ preview = { debounce = 20 } }` has no `_preview_refresh_debounced` after resume.
      Fix: keep the value on the picker and read it in `Picker:new`.

## 2. Upstream sync

- [ ] **Merge the 29 upstream commits.** (p1) [chore] The last upstream merge was March 2026 and a dry run conflicts in 11 files.
      `git merge-tree` conflicts: `doc/telescope.txt`, `actions/generate.lua`, `actions/init.lua`, `builtin/__git.lua`,
      `config.lua`, `finders/async_job_finder.lua`, `finders/async_oneshot_finder.lua`, `make_entry.lua`, `pickers.lua`,
      `pickers/layout_strategies.lua`, `scripts/minimal_init.vim`. Regenerate the doc rather than resolving its 18 hunks.
      Do the formatting item below first.
- [ ] **Restore upstream formatting before merging.** (p2) [refactor] Style churn adds conflicts and hides the fork's real changes.
      `.stylua.toml` sets `call_parentheses = "Always"` (upstream `"None"`), and parts of `layout_strategies.lua` wrap near
      100 columns against a configured 120. Measured in a scratch clone with all three sides normalized to upstream's
      config: code conflict hunks drop from 23 to 12, files from 11 to 9, `layout_strategies.lua` from 10 hunks to 1.
- [ ] **Decide on upstream's Neovim 0.11 minimum.** (p2) [chore] `e6cdb4d` requires 0.11 and drops the compat shims; the fork declares 0.10.4.
      Adopting it removes `utils.nvim011` and the shims in `utils.lua`, `debounce.lua` and `__lsp.lua`. Touches
      `plugin/telescope.lua`, the README and the CI matrix. Local nvim is 0.13-dev, so adopting looks low risk here.
- [ ] **Plan for breaking upstream changes.** (p2) [refactor] Several need follow-up beyond conflict resolution.
      `f7c673b` renames `lua/telescope/_.lua` to `async_job.lua`, which holds the fork's `LinesPipe` change and is required
      by both finders. `aa4ad82` stubs `vim.F` across 22 files, and fork-only modules (`actions/_which_key/`, finders) need
      the same treatment. `d49d056`, `cb1a129` and `3ab376c` replace the docgen tool used by `scripts/gendocs.lua`.
      `8eb2d60` switches `dynamic_workspace_symbols` to `generic_sorter`.
- [ ] **Take upstream's fixes.** (p2) [bug] Worth cherry-picking if the full merge is delayed.
      `073c000` grep_string `|` escaping; `a8bc00e` tags entry order; `e3f333b` quickfix list nr; `9377230` diagnostic code
      field (with spec); `be6a84e`, `f04ab73`, `5063384` previewer line splitting, timeouts and trailing blank line;
      `62cc799` no folding in TelescopeResults.
- [ ] **Adopt upstream's new options.** (p3) [feature] Arrive with the merge; document any that overlap fork features.
      `48d2656` show_line for live_grep and grep_string; `796ee6e` hidden-file toggle for grep pickers; `43ba8c2` buffers
      `disable_coordinates`; `028d9a0` workspace/diagnostic option.
- [ ] **Finish upstream's oneshot yield fix.** (p2) [perf] `40aedd8` fixed only the replay loop; the job read loop still yields on every line.
      `lua/telescope/finders/async_oneshot_finder.lua:122` has `if num_results % await_count then`, always true in Lua since
      0 is truthy, and upstream's copy has the same line. Line 150 is the replay loop `40aedd8` fixes. Fix both with
      `== 0`, measure with `enable_timing`, and consider sending the line 122 fix upstream.
- [ ] **Avoid tag collisions with upstream.** (p3) [chore] Fork tags v0.3.0 to v0.4.0 use the same scheme as upstream, whose latest is v0.2.2.
      An upstream v0.3.0 would collide on fetch. Options: a fork suffix or prefix, or `--no-tags` on the upstream remote.

## 3. Tests and CI

- [x] **`make test` fails on gitops specs.** (p1) [test] Three specs test a module that is not in this repo.
      `lua/tests/automated/gitops_{exports,entry,utils}_spec.lua` require `gitops.*`, which lives in
      `~/.config/nvim/lua/modules/gitops`. Local run on `cce6200`: 276 passed and 0 failed in the other specs, 5 errors in
      `gitops_exports_spec`, and `gitops_entry` and `gitops_utils` report no results, so `make test` exits 1. Fix: move the
      specs next to the module. `which_key_spec` should be unaffected.
- [ ] **CI is red on master.** (p2) [chore] The latest runs (2026-10-20) fail on every leg of Tests and on both lint jobs.
      Tests fails at "Run tests" on all 9 OS/version legs; the logs did not yield a cause, and the gitops specs are the
      likely one. Luacheck reports 8 W631 long lines (`actions/generate.lua`, `actions/_which_key/highlights.lua`) and
      `stylua --check lua` fails on 65 of 80 files. Fix the specs, wrap the lines, and resolve the formatting item in
      project 2.
- [ ] **No specs for most fork features.** (p2) [test] Grep of `lua/tests` finds no coverage for them.
      Missing: `scroll_previewer_by`, `scroll_previewer_page`, smooth scrolling, `preview.debounce`, `enable_timing`,
      `strip_path_prefix`, `themes.get_minimal`, `LinesPipe` flushing, gitsigns detection. Start with the bugs in project 1,
      each of which should get a regression spec.
- [ ] **Docgen workflow pins an unsupported Neovim.** (p2) [chore] `docgen.yml` installs 0.9.5, but `plugin/telescope.lua` requires 0.10.4.
      Replace it with upstream's simplified workflow as part of the merge, or update the pin.
- [ ] **Release workflow runs on every fork tag.** (p3) [chore] `release.yml` uploads to LuaRocks on any tag push.
      This fork should not publish under upstream's rock. Remove it, or limit it to `workflow_dispatch`.

## 4. Docs and cleanup

- [x] **Add a VERSION file.** (p2) [chore] Versions exist only as tags; the next commit should settle the source of truth.
      HEAD is 6 commits past v0.4.0 including `feat(which_key)`, so the next bump is minor (0.5.0).
- [ ] **Document the fork's features.** (p3) [docs] README is upstream's and does not say how this fork differs.
      Add a short section linking `TIMING_DIAGNOSTICS.md` and covering preview scroll actions, `preview.debounce`, which_key
      categories, gitsigns detection, `get_minimal`, `scrolling_limit`, `strip_path_prefix`. State that project.nvim and
      gitsigns are optional.
- [ ] **Fix the version in CLAUDE.md.** (p3) [docs] It says Neovim v0.10.0+ while `plugin/telescope.lua` requires 0.10.4.
      Update together with the 0.11 decision in project 2.
- [ ] **Remove stray tracked files.** (p3) [chore] Both are session notes rather than project files.
      `.claude/session-summary.md` is tracked although `.claude/` is ignored. `doc/specs/todo.md` is one URL with raw ANSI
      escapes, pointing at upstream PR 3540, which closed unmerged.
- [ ] **Remove the machine-specific test path.** (p3) [chore] `scripts/minimal_init.vim` hardcodes a lazy.nvim plenary path.
      It is also one of the merge conflicts. Prefer a `PLENARY_DIR` environment override or a local symlink at
      `../plenary.nvim`.
- [ ] **Share the timing helpers.** (p3) [refactor] `format_command` and `log_timing_stats` are duplicated in both job finders.
      Move them to one module, which also shrinks the fork's conflict surface in `finders/`.
