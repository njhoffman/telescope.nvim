local utils = require "gitops.utils"
local finder_utils = require "gitops.finders.utils"

local eq = assert.are.equal

describe("gitops.utils", function()
  describe("split_string", function()
    it("splits by space by default", function()
      local result = utils.split_string("hello world foo")
      eq("hello", result[1])
      eq("world", result[2])
      eq("foo", result[3])
    end)

    it("splits by custom separator", function()
      local result = utils.split_string("a|b|c", "|")
      eq("a", result[1])
      eq("b", result[2])
      eq("c", result[3])
    end)

    it("handles empty string", function()
      local result = utils.split_string("")
      eq(0, #result)
    end)
  end)

  describe("escape_chars", function()
    it("escapes regex special characters", function()
      eq("%%test", utils.escape_chars("%test"))
      eq("%.test", utils.escape_chars(".test"))
      eq("test%+1", utils.escape_chars("test+1"))
    end)

    it("leaves plain text unchanged", function()
      eq("hello", utils.escape_chars("hello"))
    end)
  end)

  describe("truncate_text", function()
    it("truncates long text with ellipsis", function()
      local result = utils.truncate_text("hello world this is long", 10)
      eq(10, vim.api.nvim_strwidth(result))
    end)

    it("returns short text unchanged", function()
      eq("hello", utils.truncate_text("hello", 10))
    end)
  end)

  describe("align_text", function()
    it("aligns left", function()
      local result = utils.align_text("hi", "left", 6, " ")
      eq("hi    ", result)
    end)

    it("aligns right", function()
      local result = utils.align_text("hi", "right", 6, " ")
      eq("    hi", result)
    end)

    it("aligns center", function()
      local result = utils.align_text("hi", "center", 6, " ")
      eq("  hi  ", result)
    end)
  end)

  describe("get_widths", function()
    it("calculates max widths from list entries", function()
      local entries = {
        { "abc", "de" },
        { "a", "defgh" },
      }
      local widths = utils.get_widths(entries)
      eq(3, widths[1])
      eq(5, widths[2])
    end)
  end)
end)

describe("gitops.finders.utils", function()
  describe("split_query_from_author", function()
    it("extracts author from @author syntax", function()
      local prompt, author = finder_utils.split_query_from_author("search term @john")
      eq("search term", prompt)
      eq("john", author)
    end)

    it("handles author-only query", function()
      local prompt, author = finder_utils.split_query_from_author("@john")
      eq(nil, prompt)
      eq("john", author)
    end)

    it("handles query without author", function()
      local prompt, author = finder_utils.split_query_from_author("search term")
      eq("search term", prompt)
      eq(nil, author)
    end)

    it("handles empty input", function()
      local prompt, author = finder_utils.split_query_from_author("")
      eq(nil, prompt)
      eq(nil, author)
    end)

    it("handles nil input", function()
      local prompt, author = finder_utils.split_query_from_author(nil)
      eq(nil, prompt)
      eq(nil, author)
    end)
  end)
end)
