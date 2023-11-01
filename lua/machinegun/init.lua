--- *Machinegun.doc* asdfasdf
--- *Machinegun*
---
--- MIT License Copyright (c) 2023 Guillem Ballesteros
---
--- ==============================================================================
---
--- A plugin to help you customize your setup across different machines and
--- users with a single configuration. Machinegun.nvim makes it really easy to,
--- for example, have different color schemes on your laptop and remote
--- computers or when being root.
---
--- # Setting up~
--- Full instruction available on the README. The overall steps that need to be
--- followed are:
--- 1. Find the machine ID
--- 2. Add it to the `machine` section of the plugin configuration
--- 3. Add some machine specific configuration in the settings table. Under a
---   table that is keyed with the name of the machine.
--- 4. Use the machine specific settings on your own configuration by accessing
---  them with `require("machinegun").settings` or the optional global variable.

local M = {}

local id_utils = require "machinegun.id-utils"
local utils = require "machinegun.utils"

M.config = {
  global = nil,
  default = nil,
  machines = {},
  settings = {},
}

local make_settings = function(config)
  local machine_name = id_utils.get_machine_name(config.machines)
  local user = id_utils.get_user()

  -- Get the default config if there is one otherwise just assume it is empty
  local final_config = config.settings[config.default]
  if not final_config then
    final_config = {}
  end

  -- Extend and overwrite the default with the machine (but not user) config
  local machine_config = config.settings[machine_name]
  if machine_config then
    final_config = vim.tbl_deep_extend("force", final_config, config.settings[machine_name])
  end

  -- Extend and overwrite the machine config with the user@machine config
  local user_machine_config = config.settings[user .. "@" .. machine_name]
  if user_machine_config then
    final_config = vim.tbl_deep_extend("force", final_config, user_machine_config)
  end

  return final_config
end

local validate_config = function(config)
  vim.validate({
    global = { config.global, "string", true },
    default = { config.default, "string", true },
    machines = { config.machines, "table" },
    settings = { config.settings, "table" },
  })

  for config_name, _ in pairs(config.settings) do
    local machine = utils.split_machine_and_user(config_name).machine
    if not utils.has_key(config.machines, machine) then
      vim.notify("[Machinegun] No matching id found for settings." .. machine, "WARN")
    end
  end
end

--- Module setup
---
---@param config table|nil Module config table. See |machinegun.setting up|
---
---@usage `require('machinegun').setup(opts)` To understand how to set up your opts
---  please have a look at the setting up section of the README
M.setup = function(config)
  vim.validate({ config = { config, "table", true } })
  M.config = vim.tbl_deep_extend("force", M.config, config or {})

  validate_config(M.config)
  M.settings = make_settings(M.config)

  if M.config.global then
    _G[M.config.global] = M.settings
  end
end

-- Export other functions
M.get_machine_id = id_utils.get_machine_id
M.get_user = id_utils.get_user
M.get_machine_name = id_utils.get_machine_name

return M
