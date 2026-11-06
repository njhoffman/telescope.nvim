local async = require "plenary.async"
local conf = require("telescope.config").values
local files = require "telescope.builtin.__files"
local finders = require "telescope.finders"
local log = require "telescope.log"
local pickers = require "telescope.pickers"

describe("finder logging", function()
  local old_error, old_timing_debug, logged

  before_each(function()
    old_error, old_timing_debug = log.error, log.timing.debug
    logged = {}
    log.error = function(msg)
      table.insert(logged, msg)
    end
  end)

  after_each(function()
    log.error, log.timing.debug = old_error, old_timing_debug
  end)

  local function run_failing_finder(failure)
    local picker = pickers.new({}, {
      prompt_title = "failing finder",
      finder = setmetatable({ close = function() end }, {
        __call = function()
          error(failure, 0)
        end,
      }),
      sorter = conf.generic_sorter {},
    })
    picker:find()
    vim.wait(200, function()
      return #logged > 0
    end)
    require("telescope.actions").close(picker.prompt_bufnr)
  end

  it("keeps the prefix for a string failure", function()
    run_failing_finder "boom"
    assert.are.equal("Finder failed with msg: boom", logged[1])
  end)

  it("keeps the prefix for a table failure", function()
    run_failing_finder { reason = "boom" }
    assert.is_truthy(logged[1]:find "^Finder failed with msg: {")
    assert.is_truthy(logged[1]:find("boom", 1, true))
  end)

  it("new_job honors enable_timing", function()
    local messages = {}
    log.timing.debug = function(msg)
      table.insert(messages, msg)
    end
    local done = false
    local finder = finders.new_job(function()
      return { vim.v.progpath, "--version" }
    end, function(line)
      return { value = line, ordinal = line, display = line }
    end, nil, nil, true)
    async.run(function()
      finder("prompt", function() end, function()
        done = true
      end)
    end)
    vim.wait(10000, function()
      return done
    end)
    assert.is_true(done)
    assert.is_truthy(table.concat(messages, "\n"):find("Job Finder", 1, true))
  end)

  it("live_grep passes enable_timing to its finder", function()
    local old_new_job, old_new = finders.new_job, pickers.new
    local received
    finders.new_job = function(_, _, _, _, enable_timing)
      received = enable_timing
      return { close = function() end }
    end
    pickers.new = function()
      return { find = function() end }
    end
    local ok, err = pcall(files.live_grep, { enable_timing = true })
    finders.new_job, pickers.new = old_new_job, old_new
    assert(ok, err)
    assert.is_true(received)
  end)
end)
