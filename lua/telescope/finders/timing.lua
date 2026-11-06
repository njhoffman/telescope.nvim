--- Log helpers shared by the job finders for `enable_timing`.
local log = require "telescope.log"

local timing = {}

-- `telescope.log` can be replaced, for example by a module earlier on the runtimepath, so its
-- file-only logger may be missing.
timing.log = log.timing or log

---@param command string
---@param args string[]?
---@return string
function timing.format_command(command, args)
  if args and #args > 0 then
    return command .. " " .. table.concat(args, " ")
  end
  return command
end

---@param label string: names the finder in the log, e.g. "Finder Performance"
---@param stats { command: string, duration_ms: number, entry_count: number }
function timing.log_stats(label, stats)
  local duration_sec = stats.duration_ms / 1000

  timing.log.info(
    string.format(
      "%s:\n  Command: %s\n  Total Time: %.3fs\n  Entries: %d\n  Rate: %.1f entries/sec",
      label,
      stats.command,
      duration_sec,
      stats.entry_count,
      stats.entry_count / duration_sec
    )
  )
end

return timing
