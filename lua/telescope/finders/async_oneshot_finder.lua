local async = require "plenary.async"
local async_job = require "telescope._"
local LinesPipe = require("telescope._").LinesPipe

local make_entry = require "telescope.make_entry"
local log = require "telescope.log"

local await_count = 1000

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
    "Oneshot Finder Performance:\n" ..
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
  opts = opts or {}

  local entry_maker = opts.entry_maker or make_entry.gen_from_string(opts)
  local cwd = opts.cwd
  local env = opts.env
  local fn_command = assert(opts.fn_command, "Must pass `fn_command`")
  local enable_timing = vim.F.if_nil(opts.enable_timing, false)

  local results = vim.F.if_nil(opts.results, {})
  local num_results = #results

  local job_started = false
  local job_completed = false
  local stdout = nil
  local timing_stats = {}

  local job

  return setmetatable({
    close = function()
      if job then
        job:close()
      end
    end,
    results = results,
    entry_maker = entry_maker,
  }, {
    __call = function(_, prompt, process_result, process_complete)
      if not job_started then
        local job_opts = fn_command()

        -- Log command execution
        if enable_timing then
          local cmd_string = format_command(job_opts.command, job_opts.args)
          log.info(string.format("Executing oneshot: %s", cmd_string))
          if cwd then
            log.debug(string.format("  CWD: %s", cwd))
          end
          timing_stats = {
            command = cmd_string,
            start_time = vim.loop.hrtime(),
            entry_count = 0,
            first_entry_time = nil,
          }
        end

        -- TODO: Handle writers.
        -- local writer
        -- if job_opts.writer and Job.is_job(job_opts.writer) then
        --   writer = job_opts.writer
        -- elseif job_opts.writer then
        --   writer = Job:new(job_opts.writer)
        -- end

        stdout = LinesPipe()
        job = async_job.spawn {
          command = job_opts.command,
          args = job_opts.args,
          cwd = cwd,
          env = env,

          stdout = stdout,
        }

        job_started = true
      end

      if not job_completed then
        if not vim.tbl_isempty(results) then
          for _, v in ipairs(results) do
            process_result(v)
          end
        end
        for line in stdout:iter(false) do
          num_results = num_results + 1

          -- Record first entry time
          if enable_timing and num_results == 1 then
            timing_stats.first_entry_time = vim.loop.hrtime()
            local time_to_first = (timing_stats.first_entry_time - timing_stats.start_time) / 1e6
            log.debug(string.format("Time to first entry: %.2fms", time_to_first))
          end

          if num_results % await_count then
            async.util.scheduler()
          end

          local entry = entry_maker(line)
          if entry then
            entry.index = num_results
          end
          results[num_results] = entry
          process_result(entry)
        end

        -- Log completion stats
        if enable_timing then
          timing_stats.entry_count = num_results
          timing_stats.duration_ms = (vim.loop.hrtime() - timing_stats.start_time) / 1e6
          log_timing_stats(timing_stats)
        end

        process_complete()
        job_completed = true

        return
      end

      local current_count = num_results
      for index = 1, current_count do
        -- TODO: Figure out scheduling...
        if index % await_count then
          async.util.scheduler()
        end

        if process_result(results[index]) then
          break
        end
      end

      if job_completed then
        process_complete()
      end
    end,
  })
end
