local from_entry = require "telescope.from_entry"
local make_entry = require "telescope.make_entry"

describe("strip_path_prefix", function()
  local function entry_for(filename, prefix)
    local maker = make_entry.gen_from_quickfix { strip_path_prefix = prefix, path_display = {} }
    return maker { filename = filename, lnum = 1, col = 2, text = "match" }
  end

  it("strips the prefix from the display and the search text", function()
    local entry = entry_for("/app/lua/foo.lua", "/app/")
    assert.are.equal("lua/foo.lua:1:2:match", (entry:display()))
    assert.are.equal("lua/foo.lua match", entry.ordinal)
  end)

  it("keeps the full path for opening the file", function()
    local entry = entry_for("/app/lua/foo.lua", "/app/")
    assert.are.equal("/app/lua/foo.lua", entry.filename)
    assert.are.equal("/app/lua/foo.lua", from_entry.path(entry, false, false))
  end)

  it("treats the prefix literally and leaves other paths alone", function()
    local entry = entry_for("/app.x/foo.lua", "/app.")
    assert.are.equal("x/foo.lua match", entry.ordinal)
    entry = entry_for("/other/foo.lua", "/app/")
    assert.are.equal("/other/foo.lua match", entry.ordinal)
  end)
end)
