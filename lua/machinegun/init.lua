local M = {}
local id_utils = require "machinegun.id-utils"

M.config = {
  global = nil,
  default = nil,
  machines = {},
  settings = {},
}

-- TODO: user overlays and default overlay

local run_terminal_cmd = function(command, error_message)
  local f = io.popen(command)
  if not f then
    vim.notify("[Machinegun] " .. error_message)
    return false
  end
  local out = f:read "*a" or ""
  f:close()
  return out
end

local get_user = function()
  local user = run_terminal_cmd("id -un", "Problem retrieving user name")
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

M.setup = function(config)
  vim.validate({ config = { config, "table", true } })
  M.config = vim.tbl_deep_extend("force", M.config, config or {})

  local make_settings = function()
    local machine_name = M.get_machine_name()
    if machine_name then
      return M.config.settings[machine_name]
    else
      vim.notify("[Machinegun] Retrieving the default config: " .. M.default)
      return M.config.settings[M.default]
    end
  end
  M.settings = make_settings()

  if M.config.global then
    _G[M.config.global] = M.settings
  end
end

return M
