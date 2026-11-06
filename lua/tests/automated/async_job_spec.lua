local LinesPipe = require("telescope.async_job").LinesPipe

--- Collects the lines LinesPipe:iter yields for a sequence of stdout chunks.
local function lines_of(chunks, opts)
  local index = 0
  local pipe = {
    read = function()
      index = index + 1
      return chunks[index]
    end,
  }
  local found = {}
  for line in LinesPipe.iter(pipe, false, opts) do
    table.insert(found, line)
  end
  return found
end

describe("LinesPipe:iter", function()
  it("splits newline-terminated output", function()
    assert.are.same({ "a", "b" }, lines_of { "a\nb\n" })
  end)

  it("returns a final line without a trailing newline as is", function()
    assert.are.same({ "a", "b" }, lines_of { "a\nb" })
    assert.are.same({ "only" }, lines_of { "only" })
  end)

  it("joins lines split across chunks", function()
    assert.are.same({ "a", "bc", "d" }, lines_of { "a\nb", "c\nd" })
  end)

  it("strips carriage returns", function()
    assert.are.same({ "a", "b" }, lines_of { "a\r\nb\r\n" })
  end)

  it("honors split_char for the final entry", function()
    assert.are.same({ "a", "b" }, lines_of({ "a\0b" }, { split_char = "\0" }))
    assert.are.same({ "a", "b" }, lines_of({ "a\0b\0" }, { split_char = "\0" }))
  end)

  it("yields nothing for empty output", function()
    assert.are.same({}, lines_of {})
  end)
end)
