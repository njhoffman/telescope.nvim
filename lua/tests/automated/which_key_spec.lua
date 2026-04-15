local action_utils = require "telescope.actions.utils"
local display = require "telescope.actions._which_key.display"
local layout = require "telescope.actions._which_key.layout"

local eq = assert.are.equal
local same = assert.are.same

describe("actions._which_key", function()
  describe("description parsing", function()
    it("parses legacy telescope| prefix with no origin", function()
      local body, origin, is_json = action_utils._parse_telescope_desc("telescope|select_default")
      eq("select_default", body)
      eq(nil, origin)
      eq(false, is_json)
    end)

    it("parses origin-tagged telescope:picker| prefix", function()
      local body, origin = action_utils._parse_telescope_desc("telescope:picker|my_action")
      eq("my_action", body)
      eq("picker", origin)
    end)

    it("parses origin-tagged telescope:user_global| prefix", function()
      local body, origin = action_utils._parse_telescope_desc("telescope:user_global|open_in_split")
      eq("open_in_split", body)
      eq("user_global", origin)
    end)

    it("parses origin-tagged telescope:default| prefix", function()
      local body, origin = action_utils._parse_telescope_desc("telescope:default|close")
      eq("close", body)
      eq("default", origin)
    end)

    it("parses origin-tagged telescopej:picker| json prefix", function()
      local body, origin, is_json = action_utils._parse_telescope_desc('telescopej:picker|{"source":"x"}')
      eq('{"source":"x"}', body)
      eq("picker", origin)
      eq(true, is_json)
    end)

    it("returns nil for non-telescope descriptions", function()
      local body = action_utils._parse_telescope_desc("some random desc")
      eq(nil, body)
    end)

    it("returns nil for missing desc", function()
      local body = action_utils._parse_telescope_desc(nil)
      eq(nil, body)
    end)
  end)

  describe("key substitution", function()
    it("applies exact key_labels match", function()
      local result = display.substitute("<CR>", { key_labels = { ["<CR>"] = "Enter" } })
      eq("Enter", result)
    end)

    it("returns raw keybind when no label matches", function()
      local result = display.substitute("<C-n>", { key_labels = { ["<CR>"] = "Enter" } })
      eq("<C-n>", result)
    end)

    it("applies replace_keys pattern pairs when no label matches", function()
      local result = display.substitute("<Plug>Thing", {
        replace_keys = { { "^<Plug>", "P:" } },
      })
      eq("P:Thing", result)
    end)

    it("key_labels wins over replace_keys when both match", function()
      local result = display.substitute("<CR>", {
        key_labels = { ["<CR>"] = "Enter" },
        replace_keys = { { "^<", "[" } },
      })
      eq("Enter", result)
    end)

    it("merges use_default_key_labels under user-provided labels", function()
      local result = display.substitute("<Esc>", {
        use_default_key_labels = true,
        key_labels = { ["<Esc>"] = "ESCAPE" },
      })
      eq("ESCAPE", result)
    end)

    it("use_default_key_labels fills in unmapped keys", function()
      local result = display.substitute("<Tab>", { use_default_key_labels = true })
      eq("Tab", result)
    end)

    it("handles empty opts gracefully", function()
      eq("<C-x>", display.substitute("<C-x>", {}))
    end)
  end)

  describe("priority truncation", function()
    local function make_mapping(origin, name)
      return { mode = "i", keybind = "<C-x>", name = name, origin = origin }
    end

    it("returns input unchanged when under capacity", function()
      local mappings = {
        make_mapping("picker", "p1"),
        make_mapping("default", "d1"),
      }
      local kept, hidden = layout.truncate(mappings, 5, { "default", "user_global" })
      eq(2, #kept)
      eq(0, hidden)
    end)

    it("drops default-origin first", function()
      local mappings = {
        make_mapping("picker", "p1"),
        make_mapping("picker", "p2"),
        make_mapping("user_global", "u1"),
        make_mapping("default", "d1"),
        make_mapping("default", "d2"),
      }
      local kept, hidden = layout.truncate(mappings, 3, { "default", "user_global" })
      eq(3, #kept)
      eq(2, hidden)
      -- picker + user_global should remain
      local origins = {}
      for _, m in ipairs(kept) do
        origins[m.origin] = (origins[m.origin] or 0) + 1
      end
      eq(2, origins.picker)
      eq(1, origins.user_global)
      eq(nil, origins.default)
    end)

    it("drops user_global after defaults when still overflowing", function()
      local mappings = {
        make_mapping("picker", "p1"),
        make_mapping("user_global", "u1"),
        make_mapping("user_global", "u2"),
        make_mapping("default", "d1"),
      }
      local kept, hidden = layout.truncate(mappings, 1, { "default", "user_global" })
      eq(1, #kept)
      eq(3, hidden)
      eq("picker", kept[1].origin)
    end)

    it("still clips picker-only mappings if truly too many", function()
      local mappings = {
        make_mapping("picker", "p1"),
        make_mapping("picker", "p2"),
        make_mapping("picker", "p3"),
      }
      local kept, hidden = layout.truncate(mappings, 2, { "default", "user_global" })
      eq(2, #kept)
      eq(1, hidden)
    end)
  end)

  describe("layout dimensions", function()
    it("computes at least one column/row regardless of cramped editor", function()
      local opts = {
        column_padding = "  ",
        mode_width = 1,
        keybind_width = 7,
        name_width = 30,
        separator = " -> ",
        max_height = 0.4,
      }
      local num_cols, num_rows, capacity = layout.dimensions({ {}, {}, {} }, opts, "    ")
      assert.is_true(num_cols >= 1)
      assert.is_true(num_rows >= 1)
      eq(num_cols * num_rows, capacity)
    end)
  end)
end)
