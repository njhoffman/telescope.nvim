local finder_utils = require "gitops.finders.utils"

local eq = assert.are.equal

describe("gitops.finders.utils.git_log_entry_maker", function()
  it("parses a standard git log line", function()
    local line = "abc1234|(2 hours ago)|fix: update readme|John Doe"
    local entry = finder_utils.git_log_entry_maker(line)

    eq("abc1234", entry.value.sha)
    eq("(2 hours)", entry.value.date)
    eq("fix: update readme", entry.value.message)
    eq("John Doe", entry.value.author)
  end)

  it("sets ordinal from author and message", function()
    local line = "abc1234|(3 days ago)|add feature|Jane"
    local entry = finder_utils.git_log_entry_maker(line)

    eq("Jane add feature", entry.ordinal)
  end)

  it("sets commit_hash in opts", function()
    local line = "abc1234|(1 day ago)|msg|Author"
    local entry = finder_utils.git_log_entry_maker(line)

    eq("abc1234", entry.opts.commit_hash)
  end)

  it("shortens year-based dates", function()
    local line = "abc1234|(2 years, 3 months ago)|msg|Author"
    local entry = finder_utils.git_log_entry_maker(line)

    assert.truthy(string.find(entry.value.date, "yr"))
    assert.truthy(string.find(entry.value.date, "mo"))
  end)

  it("removes 'ago' from dates", function()
    local line = "abc1234|(5 minutes ago)|msg|Author"
    local entry = finder_utils.git_log_entry_maker(line)

    assert.falsy(string.find(entry.value.date, "ago"))
  end)

  it("produces a callable display function", function()
    local line = "abc1234|(1 hour ago)|test message|Dev"
    local entry = finder_utils.git_log_entry_maker(line)

    eq("function", type(entry.display))
  end)
end)
