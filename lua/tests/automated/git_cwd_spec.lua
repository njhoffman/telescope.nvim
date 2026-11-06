local git = require "telescope.builtin.__git"
local pickers = require "telescope.pickers"

describe("git pickers cwd detection", function()
  local repo_a, repo_b, bufnr, old_pickers_new, previous_bufnr, captured

  local function make_repo()
    local dir = vim.fn.tempname()
    vim.fn.mkdir(dir, "p")
    local result = vim.system({ "git", "-C", dir, "init", "-q" }, { text = true }):wait()
    assert(result.code == 0, result.stderr)
    return vim.uv.fs_realpath(dir)
  end

  before_each(function()
    repo_a, repo_b = make_repo(), make_repo()
    captured = nil
    old_pickers_new = pickers.new
    pickers.new = function(opts)
      captured = opts
      return { find = function() end }
    end
    previous_bufnr = vim.api.nvim_get_current_buf()
    bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(bufnr)
    vim.b[bufnr].gitsigns_status_dict = { gitdir = repo_a .. "/.git", root = repo_a }
  end)

  after_each(function()
    pickers.new = old_pickers_new
    vim.api.nvim_set_current_buf(previous_bufnr)
    vim.api.nvim_buf_delete(bufnr, { force = true })
    vim.fn.delete(repo_a, "rf")
    vim.fn.delete(repo_b, "rf")
  end)

  it("follows the gitsigns repo of the current buffer by default", function()
    git.files {}
    assert.are.equal(repo_a, captured.cwd)
    assert.are.equal(repo_a .. "/.git", captured.gitdir)
    assert.are.equal(repo_a, captured.toplevel)
  end)

  it("prefers an explicit cwd over the gitsigns repo", function()
    git.files { cwd = repo_b }
    -- git reports forward slashes on Windows
    assert.are.equal(vim.fs.normalize(repo_b), vim.fs.normalize(captured.cwd))
    assert.is_nil(captured.gitdir)
    assert.is_nil(captured.toplevel)
  end)

  it("uses the gitsigns repo for use_file_path, even without a git root", function()
    git.files { use_file_path = true, use_git_root = false }
    assert.are.equal(repo_a, captured.cwd)
    assert.are.equal(repo_a .. "/.git", captured.gitdir)
  end)

  it("keeps the current directory when use_git_root is false", function()
    git.files { use_git_root = false }
    assert.are.equal(vim.uv.cwd(), captured.cwd)
    assert.are.equal(repo_a .. "/.git", captured.gitdir)
  end)
end)
