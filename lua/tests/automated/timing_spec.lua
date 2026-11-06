local async = require "plenary.async"
local actions = require "telescope.actions"
local conf = require("telescope.config").values
local finders = require "telescope.finders"
local log = require "telescope.log"
local pickers = require "telescope.pickers"

describe("timing diagnostics", function()
  local old_info, old_debug, messages

  before_each(function()
    old_info, old_debug = log.timing.info, log.timing.debug
    messages = {}
    local capture = function(msg)
      table.insert(messages, msg)
    end
    log.timing.info, log.timing.debug = capture, capture
  end)

  after_each(function()
    log.timing.info, log.timing.debug = old_info, old_debug
  end)

  local function logged(text)
    return table.concat(messages, "\n"):find(text, 1, true) ~= nil
  end

  --- Runs a finder to completion and returns how many entries it produced.
  local function run(finder)
    local entries, done = 0, false
    async.run(function()
      finder("prompt", function()
        entries = entries + 1
      end, function()
        done = true
      end)
    end)
    vim.wait(10000, function()
      return done
    end)
    assert.is_true(done)
    return entries
  end

  -- Finders consume the list they are given.
  local function command()
    return { vim.v.progpath, "--version" }
  end

  it("reports oneshot finder performance", function()
    local entries = run(finders.new_oneshot_job(command(), { enable_timing = true }))
    assert.is_true(entries > 0)
    assert.is_true(logged "Job Oneshot:")
    assert.is_true(logged "First entry:")
    assert.is_true(logged "Oneshot Finder Performance:")
    assert.is_true(logged(table.concat(command(), " ")))
    assert.is_true(logged(("Entries: %d"):format(entries)))
  end)

  it("reports job finder performance", function()
    local entries = run(finders.new_async_job {
      command_generator = command,
      entry_maker = function(line)
        return { value = line, ordinal = line, display = line }
      end,
      enable_timing = true,
    })
    assert.is_true(logged "Job Finder:")
    assert.is_true(logged "Finder Performance:")
    assert.is_true(logged(("Entries: %d"):format(entries)))
  end)

  it("writes to the log file without echoing to :messages", function()
    log.timing.info, log.timing.debug = old_info, old_debug
    log.timing.info "timing-spec-marker"
    vim.wait(50)
    assert.is_nil(vim.fn.execute("messages"):find("timing-spec-marker", 1, true))
  end)

  it("falls back to telescope.log when it has no timing logger", function()
    local real_log, real_timing = package.loaded["telescope.log"], package.loaded["telescope.finders.timing"]
    local infos = {}
    package.loaded["telescope.log"] = {
      info = function(msg)
        table.insert(infos, msg)
      end,
    }
    package.loaded["telescope.finders.timing"] = nil
    local ok, err = pcall(function()
      require("telescope.finders.timing").log_stats("Spec", { command = "x", duration_ms = 1, entry_count = 1 })
    end)
    package.loaded["telescope.log"], package.loaded["telescope.finders.timing"] = real_log, real_timing
    assert(ok, err)
    assert.is_truthy(infos[1]:find("Spec:", 1, true))
  end)

  it("stays quiet when disabled", function()
    run(finders.new_oneshot_job(command(), { enable_timing = false }))
    assert.is_false(logged "Performance:")
  end)

  it("reports the picker lifecycle", function()
    local picker = pickers.new({ enable_timing = true }, {
      prompt_title = "timing spec",
      finder = finders.new_table { results = { "a", "b" } },
      sorter = conf.generic_sorter {},
    })
    picker:find()
    vim.wait(2000, function()
      return logged "Completed:"
    end)
    actions.close(picker.prompt_bufnr)

    assert.is_true(logged "=== Picker Timing [timing spec] ===")
    assert.is_true(logged "Input ready:")
    assert.is_true(logged "2 results [timing spec]")
    assert.is_true(logged "=== Picker Close  [timing spec] ===")
  end)
end)
