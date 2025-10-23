# Telescope Timing Diagnostics

This document describes the timing diagnostics feature added to telescope.nvim for profiling picker and finder performance.

## Overview

The timing diagnostics feature provides detailed performance metrics for:
- External command execution (command string, arguments, working directory)
- Data loading performance (entries/second, time to first entry)
- UI responsiveness (layout creation, initialization, time until interactive)
- Result display latency (time to first result appearing)

## Enabling Timing Diagnostics

### Global Configuration

Enable timing for all pickers via your telescope setup:

```lua
require('telescope').setup({
  defaults = {
    enable_timing = true,
  },
})
```

### Per-Picker Configuration

Enable timing for specific pickers:

```lua
require('telescope.builtin').find_files({
  enable_timing = true,
})
```

### Per-Finder Configuration

For custom finders using external commands:

```lua
local finders = require('telescope.finders')

local my_finder = finders.new_async_job({
  command_generator = function(prompt)
    return { 'rg', '--files', prompt }
  end,
  enable_timing = true,
})
```

## Metrics Collected

### Command Execution Metrics

When timing is enabled for finders that execute external commands, the following information is logged:

**Command Information:**
- Full command string with arguments
- Working directory (if specified)

**Example:**
```
Executing: rg --files --hidden
  CWD: /home/user/project
```

### Data Loading Metrics

**Time to First Entry:**
- Measures latency from command start to first result received
- Helps identify command startup overhead

**Loading Performance:**
- Total entries loaded
- Total time taken
- Loading rate (entries/second)

**Example:**
```
Time to first entry: 12.34ms
Finder Performance:
  Command: rg --files --hidden
  Total Time: 0.456s
  Entries: 1234
  Rate: 2705.3 entries/sec
```

### UI Responsiveness Metrics

**Layout Creation:**
- Time to create and mount the telescope windows

**UI Initialization:**
- Time to set up buffers, mappings, and UI state

**Ready for Input:**
- Total time from picker start to user being able to type
- Most important metric for perceived responsiveness

**Example:**
```
=== Picker Timing Diagnostics ===
Layout creation and mount: 15.23ms
UI initialization: 8.67ms
Picker ready for input: 25.12ms
```

### Result Display Metrics

**Time to First Result Displayed:**
- Measures when first result becomes visible in the results window
- Accounts for sorting, filtering, and display overhead

**Example:**
```
Time to first result displayed: 18.45ms
```

## Viewing Timing Data

All timing metrics are written to the telescope log file. To view the log:

### Set Log Level

Set the log level to see timing information:

```lua
-- In your telescope setup or init.lua
require('telescope.log').level = 'info'  -- For summary metrics
-- or
require('telescope.log').level = 'debug' -- For detailed metrics
```

### View Log File

The log file location depends on your system:

**Linux/macOS:**
```bash
tail -f ~/.cache/nvim/telescope.log
```

**Windows:**
```powershell
Get-Content -Wait ~/AppData/Local/nvim-data/telescope.log
```

**From Neovim:**
```vim
:lua print(require('plenary.log').logfile)
```

## Example Use Cases

### Profiling find_files Performance

```lua
-- Profile find_files to see if ripgrep is the bottleneck
require('telescope.builtin').find_files({
  enable_timing = true,
  -- Try different tools
  find_command = { 'fd', '--type', 'f' },
})
```

Check the log to compare:
- Command execution time
- Entries loaded per second
- Time to first result

### Profiling live_grep Responsiveness

```lua
require('telescope.builtin').live_grep({
  enable_timing = true,
})
```

For each keystroke, you'll see:
- New command execution
- Time to first entry (latency)
- Loading rate

### Debugging Slow Picker Startup

```lua
require('telescope.builtin').buffers({
  enable_timing = true,
})
```

Check metrics to identify bottlenecks:
- If "Layout creation" is slow: layout_strategy or window creation issue
- If "UI initialization" is slow: too many buffers or complex entry_maker
- If "Picker ready for input" is slow: overall startup overhead

## Performance Optimization Tips

Based on timing metrics, you can optimize:

### Slow Command Execution
- Use faster tools (fd vs find, rg vs ag)
- Add better filters/ignore patterns
- Consider caching for frequently run searches

### Slow Data Loading
- Limit maximum_results
- Optimize entry_maker functions
- Use streaming finders (async_job) instead of oneshot

### Slow UI Responsiveness
- Simplify layout_strategy
- Reduce preview window overhead (disable for text-only pickers)
- Optimize sorter selection

### Slow Result Display
- Simplify entry_display functions
- Reduce file_ignore_patterns complexity
- Optimize sorter scoring functions

## Implementation Details

### Modified Files

The timing diagnostics feature modifies:

1. **lua/telescope/finders/async_job_finder.lua**
   - Logs command execution
   - Tracks time to first entry
   - Calculates loading rate

2. **lua/telescope/finders/async_oneshot_finder.lua**
   - Same metrics for oneshot jobs
   - Tracks total completion time

3. **lua/telescope/pickers.lua**
   - Tracks UI creation phases
   - Measures time to interactivity
   - Logs first result display

4. **lua/telescope/config.lua**
   - Adds `enable_timing` configuration option

### Timing Points

```
Picker Start
    ↓
Layout Creation [MEASURED]
    ↓
Layout Mount [MEASURED]
    ↓
UI Initialization [MEASURED]
    ↓
Ready for Input [MEASURED] ← User can now type
    ↓
Command Execution Start [LOGGED]
    ↓
First Entry Received [MEASURED]
    ↓
Entry Processing & Sorting
    ↓
First Result Displayed [MEASURED]
    ↓
Loading Complete [MEASURED]
```

## Overhead

The timing feature has minimal overhead:
- Only active when `enable_timing = true`
- Uses high-resolution timers (`vim.loop.hrtime()`)
- Logging is asynchronous via plenary.log
- No performance impact when disabled

## Troubleshooting

### No timing output in log

1. Check log level: `require('telescope.log').level = 'info'`
2. Verify timing is enabled in config
3. Check log file path is correct
4. Ensure picker/finder supports timing (command-based finders)

### Timing seems incorrect

1. High variability is normal for first run (disk cache)
2. Background processes can affect timing
3. Multiple concurrent pickers may interfere
4. Very fast operations (<1ms) have measurement uncertainty

## Future Enhancements

Potential additions:
- CSV/JSON export of timing data
- Statistical aggregation (min/max/avg over multiple runs)
- Performance regression detection
- Visual performance dashboard
- Per-keystroke latency tracking for live_grep
- Memory usage profiling
