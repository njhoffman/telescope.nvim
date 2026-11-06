local new = require("plenary.log").new

local log = new {
  plugin = "telescope",
  level = "info",
}

-- `enable_timing` output goes to the same file, but stays out of the message area.
log.timing = new {
  plugin = "telescope",
  level = "info",
  use_console = false,
}

return log
