local extensions = {}

extensions._loaded = {}
extensions._config = {}
extensions._health = {}
extensions._has_setup = {}

local load_extension = function(name)
  local ok, ext = pcall(require, "telescope._extensions." .. name)
  if not ok then
    error(string.format("'%s' extension doesn't exist or isn't installed: %s", name, ext))
  end
  return ext
end

--- `load` and first use both reach this, and an extension should only be set up once.
local setup_once = function(name, ext)
  if ext.setup and not extensions._has_setup[name] then
    ext.setup(extensions._config[name] or {}, require("telescope.config").values)
    extensions._has_setup[name] = true
  end
end

--- Tells a picker which export opened it, through `opts.__name`.
local with_name = function(name, fn)
  return function(opts, ...)
    if opts ~= nil and type(opts) ~= "table" then
      return fn(opts, ...)
    end
    return fn(vim.tbl_deep_extend("force", {}, opts or {}, { __name = name }), ...)
  end
end

extensions.manager = setmetatable({}, {
  __index = function(t, k)
    local ext = load_extension(k)
    t[k] = ext.exports or {}
    setup_once(k, ext)
    for key, value in pairs(t[k]) do
      if type(value) == "function" then
        t[k][key] = with_name(k .. "." .. key, value)
      end
    end
    extensions._health[k] = ext.health

    return t[k]
  end,
})

--- Register an extension module.
---
--- Extensions have several important keys.
---     - setup:
---         function(ext_config, config) -> nil
---
---         Called when first loading the extension.
---         The first parameter is the config passed by the user
---             in telescope setup. The second parameter is the resulting
---             config.values after applying the users setup defaults.
---
---         It is acceptable for a plugin to override values in config,
---         as some plugins will be installed simply to manage some setup,
---         install some sorter, etc.
---
---     - exports:
---         table
---
---         Only the items in `exports` will be exposed on the  resulting
---         module that users can access via require('telescope').extensions.foo
---         Also, any top-level key-value pairs in exports where the value is a function and the
---         key doesn't start with an underscore will be included when calling the `builtin` picker
---         with the `include_extensions` option enabled.
---
---         Other things in the module will not be accessible. This is the public API
---         for your extension. Consider not breaking it a lot :laugh:
---
--- TODO:
---     - actions
extensions.register = function(mod)
  return mod
end

extensions.load = function(name)
  local ext = load_extension(name)
  setup_once(name, ext)
  return extensions.manager[name]
end

extensions.set_config = function(extensions_config)
  extensions._config = vim.deepcopy(extensions_config or {})
end

return extensions
