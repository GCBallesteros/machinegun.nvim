local M = {}

M.run_terminal_cmd = function(command, error_message)
  local f = io.popen(command)
  if not f then
    vim.notify("[Machinegun] " .. error_message, "ERROR")
    return false
  end
  local out = f:read "*a" or ""
  f:close()
  return out
end

M.split_machine_and_user = function(config_name)
  local user, machine = string.match(config_name, "([^@]*)@?(.*)")

  -- whoopsy we got it the wrong way around
  if machine == "" then
    machine = user
    user = nil
  end

  return { user = user, machine = machine }
end

M.has_key = function(tab, val)
  for key, _ in pairs(tab) do
    if key == val then
      return true
    end
  end

  return false
end

return M
