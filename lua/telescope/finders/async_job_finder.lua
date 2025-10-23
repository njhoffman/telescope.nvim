local async_job = require "telescope._"
local LinesPipe = require("telescope._").LinesPipe

local make_entry = require "telescope.make_entry"
local log = require "telescope.log"

local function format_command(command, args)
  local cmd_str = command
  if args and #args > 0 then
    cmd_str = cmd_str .. " " .. table.concat(args, " ")
  end
  return cmd_str
end

local function log_timing_stats(stats)
  local duration_sec = stats.duration_ms / 1000
  local entries_per_sec = stats.entry_count / duration_sec

  log.info(string.format(
    "Finder Performance:\n" ..
    "  Command: %s\n" ..
    "  Total Time: %.3fs\n" ..
    "  Entries: %d\n" ..
    "  Rate: %.1f entries/sec",
    stats.command,
    duration_sec,
    stats.entry_count,
    entries_per_sec
  ))
end

return function(opts)
  log.trace("Creating async_job:", opts)
  local entry_maker = opts.entry_maker or make_entry.gen_from_string(opts)

  -- Enable timing diagnostics if requested
  local enable_timing = vim.F.if_nil(opts.enable_timing, false)

  local fn_command = function(prompt)
    local command_list = opts.command_generator(prompt)
    if command_list == nil then
      return nil
    end

    local command = table.remove(command_list, 1)

    local res = {
      command = command,
      args = command_list,
    }

    return res
  end

  local job
  local timing_stats = {}

  local callable = function(_, prompt, process_result, process_complete)
    if job then
      job:close(true)
    end

    local job_opts = fn_command(prompt)
    if not job_opts then
      process_complete()
      return
    end

    -- Log command execution
    local cmd_string = format_command(job_opts.command, job_opts.args)
    if enable_timing then
      log.info(string.format("Executing: %s", cmd_string))
      if job_opts.cwd then
        log.debug(string.format("  CWD: %s", job_opts.cwd))
      end
      timing_stats = {
        command = cmd_string,
        start_time = vim.loop.hrtime(),
        entry_count = 0,
        first_entry_time = nil,
      }
    end

    local writer = nil
    -- if job_opts.writer and Job.is_job(job_opts.writer) then
    --   writer = job_opts.writer
    if opts.writer then
      error "async_job_finder.writer is not yet implemented"
      writer = async_job.writer(opts.writer)
    end

    local stdout = LinesPipe()

    job = async_job.spawn {
      command = job_opts.command,
      args = job_opts.args,
      cwd = job_opts.cwd or opts.cwd,
      env = job_opts.env or opts.env,
      writer = writer,

      stdout = stdout,
    }

    local line_num = 0
    for line in stdout:iter(true) do
      line_num = line_num + 1

      -- Record first entry time
      if enable_timing and line_num == 1 then
        timing_stats.first_entry_time = vim.loop.hrtime()
        local time_to_first = (timing_stats.first_entry_time - timing_stats.start_time) / 1e6
        log.debug(string.format("Time to first entry: %.2fms", time_to_first))
      end

      local entry = entry_maker(line)
      if entry then
        entry.index = line_num
      end

      if enable_timing then
        timing_stats.entry_count = line_num
      end

      if process_result(entry) then
        return
      end
    end

    -- Log completion stats
    if enable_timing then
      timing_stats.duration_ms = (vim.loop.hrtime() - timing_stats.start_time) / 1e6
      log_timing_stats(timing_stats)
    end

    process_complete()
  end

  return setmetatable({
    close = function()
      if job then
        job:close(true)
      end
    end,
  }, {
    __call = callable,
  })
end
