local M = {}

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

local get_os = function()
  local operating_system = run_terminal_cmd("uname -s", "Problem running `uname`")
  if operating_system then
    return string.lower(string.gsub(operating_system, "\n$", ""))
  else
    return false
  end
end

M.get_machine_id = function()
  local operating_system = get_os()
  if not operating_system then
    vim.notify "[Machinegun] Could not retrieve current OS"
    return false
  end

  -- The purpose of the hash is to hide the actual machine ID in case the code
  -- ends up on Github or other place publicly available
  local id_cmd
  if string.find(operating_system, "linux") then
    id_cmd = [[cat /etc/machine-id | shasum -a 1 | cut -f 1 -d  " "]]
  elseif string.find(operating_system, "darwin") then
    id_cmd =
      -- [[dscl /Search -read "/Users/$USER" GeneratedUID | cut -d ' ' -f2 | shasum -a 1 | cut -f 1 -d " "]]
    -- https://apple.stackexchange.com/questions/342042/how-can-i-query-the-hardware-uuid-of-a-mac-programmatically-from-a-command-line
      [[ioreg -d2 -c IOPlatformExpertDevice | awk -F\" '/IOPlatformUUID/{print $(NF-1)}' | shasum -a 1 | cut -f 1 -d  " "]]
  else
    vim.notify("[Machinegun] The retrieved OS " .. operating_system .. " could not be identified")
    return false
  end

  local machine_id = run_terminal_cmd(id_cmd, "Problem retriving machine-id")
  if machine_id then
    return string.gsub(machine_id, "\n$", "")
  else
    return false
  end
end

return M
