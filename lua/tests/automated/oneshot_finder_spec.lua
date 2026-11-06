local async = require "plenary.async"
local oneshot = require "telescope.finders.async_oneshot_finder"

describe("oneshot finder", function()
  local total = 5000
  local script, real_scheduler

  before_each(function()
    real_scheduler = async.util.scheduler
    script = vim.fn.tempname() .. ".lua"
    vim.fn.writefile({ ("for i = 1, %d do io.write(i, '\\n') end"):format(total) }, script)
  end)

  after_each(function()
    async.util.scheduler = real_scheduler
    vim.fn.delete(script)
  end)

  it("reads output on the main loop without yielding for every line", function()
    local yields, entries, api_error, done = 0, 0, nil, false
    async.util.scheduler = function(...)
      yields = yields + 1
      return real_scheduler(...)
    end

    local finder = oneshot {
      fn_command = function()
        return { command = vim.v.progpath, args = { "--clean", "--headless", "-l", script } }
      end,
      entry_maker = function(line)
        -- Entry makers may use the API, which is not allowed right after a pipe read.
        local ok, err = pcall(vim.api.nvim_get_current_buf)
        api_error = api_error or (not ok and err) or nil
        return { value = line, ordinal = line, display = line }
      end,
    }

    async.run(function()
      finder("", function()
        entries = entries + 1
      end, function()
        done = true
      end)
    end)
    vim.wait(20000, function()
      return done
    end, 5)

    assert.is_true(done)
    assert.are.equal(total, entries)
    assert.is_nil(api_error)
    -- One yield per pipe read, and Windows delivers many small chunks.
    assert.is_true(yields < total / 2, "yielded " .. yields .. " times")
  end)
end)
