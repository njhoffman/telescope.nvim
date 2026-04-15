describe("gitops module exports", function()
  describe("core", function()
    local core = require "gitops.core"

    it("exports all expected picker functions", function()
      local expected = { "files", "stash", "status", "commits", "bcommits", "branches" }
      for _, key in ipairs(expected) do
        assert.is_not_nil(core[key], "missing core export: " .. key)
        assert.equals("function", type(core[key]), "core." .. key .. " should be a function")
      end
    end)

    it("exports stats functions", function()
      assert.equals("function", type(core.commits_stats))
      assert.equals("function", type(core.bcommits_stats))
    end)
  end)

  describe("diff", function()
    local diff = require "gitops.diff"

    it("exports all expected diff functions", function()
      local expected = { "diff_commit_line", "diff_commit_file", "diff_branch", "diff_branch_file" }
      for _, key in ipairs(expected) do
        assert.is_not_nil(diff[key], "missing diff export: " .. key)
        assert.equals("function", type(diff[key]), "diff." .. key .. " should be a function")
      end
    end)
  end)

  describe("search", function()
    local search = require "gitops.search"

    it("exports all expected search functions", function()
      local expected = { "search_commits", "search_commits_file", "show_custom_functions", "checkout_reflog" }
      for _, key in ipairs(expected) do
        assert.is_not_nil(search[key], "missing search export: " .. key)
        assert.equals("function", type(search[key]), "search." .. key .. " should be a function")
      end
    end)
  end)

  describe("finders", function()
    local finders = require "gitops.finders"

    it("exports all expected finder functions", function()
      local expected = { "git_branches", "git_log_location", "git_log_content", "git_log_file", "changed_files_on_branch" }
      for _, key in ipairs(expected) do
        assert.is_not_nil(finders[key], "missing finders export: " .. key)
        assert.equals("function", type(finders[key]), "finders." .. key .. " should be a function")
      end
    end)
  end)

  describe("previewers", function()
    local previewers = require "gitops.previewers"

    it("exports all expected previewer functions", function()
      local expected = {
        "diff_delta", "diff_commit_to_parent", "diff_commit_to_head", "diff_commit_as_was",
        "branch_log", "diff_stash", "commit_message",
        "changed_files_on_current_branch", "diff_branch_file_previewer",
        "diff_content_previewer", "diff_commit_file_previewer",
      }
      for _, key in ipairs(expected) do
        assert.is_not_nil(previewers[key], "missing previewers export: " .. key)
      end
    end)
  end)
end)
