local M = {}
local id_utils = require "machinegun.id-utils"
local utils = require "machinegun.utils"

M.config = {
  global = nil,
  default = nil,
  machines = {},
  settings = {},
}

M.get_user = function()
  local user = utils.run_terminal_cmd("id -un", "Problem retrieving user name")
  if user then
    return string.gsub(user, "\n$", "")
  else
    return false
  end
end

M.get_machine_name = function()
  local machine_id = id_utils.get_machine_id()
  if not machine_id then
    return false
  end

  for machine_name, mid in pairs(M.config.machines) do
    local check_id = vim.fn.match(machine_id, "^" .. mid) == 0
    if check_id then
      return machine_name
    end
  end

  -- Didn't find the machine
  return false
end

local make_settings = function(config)
  local machine_name = M.get_machine_name()
  local user = M.get_user()

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

M.setup = function(config)
  vim.validate({ config = { config, "table", true } })
  M.config = vim.tbl_deep_extend("force", M.config, config or {})

  validate_config(M.config)
  M.settings = make_settings(M.config)

  if M.config.global then
    _G[M.config.global] = M.settings
  end
end

return M
