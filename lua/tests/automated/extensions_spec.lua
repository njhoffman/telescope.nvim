local extensions = require "telescope._extensions"

describe("telescope extensions", function()
  local setups, received

  before_each(function()
    setups, received = 0, {}
    extensions.manager.spec_ext = nil
    package.loaded["telescope._extensions.spec_ext"] = nil
    package.preload["telescope._extensions.spec_ext"] = function()
      return {
        setup = function()
          setups = setups + 1
        end,
        exports = {
          pick = function(...)
            received = { n = select("#", ...), ... }
            return "picked"
          end,
          value = "not a function",
        },
      }
    end
    rawset(extensions.manager, "spec_ext", nil)
    extensions._has_setup = {}
  end)

  after_each(function()
    rawset(extensions.manager, "spec_ext", nil)
    package.preload["telescope._extensions.spec_ext"] = nil
    package.loaded["telescope._extensions.spec_ext"] = nil
  end)

  it("sets up an extension once across load and first use", function()
    extensions.load "spec_ext"
    assert.is_not_nil(extensions.manager.spec_ext)
    assert.are.equal(1, setups)
  end)

  it("tells pickers which export opened them", function()
    assert.are.equal("picked", extensions.manager.spec_ext.pick { search = "x" })
    assert.are.equal("spec_ext.pick", received[1].__name)
    assert.are.equal("x", received[1].search)
  end)

  it("accepts a call without options", function()
    extensions.manager.spec_ext.pick()
    assert.are.equal("spec_ext.pick", received[1].__name)
  end)

  it("passes other arguments through untouched", function()
    extensions.manager.spec_ext.pick("word", 2)
    assert.are.same({ n = 2, "word", 2 }, received)
  end)

  it("does not modify the caller's options", function()
    local opts = { search = "x" }
    extensions.manager.spec_ext.pick(opts)
    assert.is_nil(opts.__name)
  end)

  it("leaves other exports alone", function()
    assert.are.equal("not a function", extensions.manager.spec_ext.value)
  end)

  it("copies the extension config", function()
    local config = { spec_ext = { a = 1 } }
    extensions.set_config(config)
    config.spec_ext.a = 2
    assert.are.equal(1, extensions._config.spec_ext.a)
    extensions.set_config {}
  end)
end)
