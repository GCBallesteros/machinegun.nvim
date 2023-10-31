local M = {}
local utils = require "machinegun.utils"

--- Returns an SHA1 hash of machine UUID.
---
---@return string\|boolean UUID for the machine. If false the retrieval failed
M.get_machine_id = function()
  local operating_system = vim.loop.os_uname().sysname
  local id_cmd
  if string.find(operating_system, "Linux") then
    id_cmd = [[cat /etc/machine-id | shasum -a 1 | cut -f 1 -d  " "]]
  elseif string.find(operating_system, "Darwin") then
    id_cmd =
      -- https://apple.stackexchange.com/questions/342042/how-can-i-query-the-hardware-uuid-of-a-mac-programmatically-from-a-command-line
      [[ioreg -d2 -c IOPlatformExpertDevice | awk -F\" '/IOPlatformUUID/{print $(NF-1)}' | shasum -a 1 | cut -f 1 -d  " "]]
  else
    vim.notify("[Machinegun] The retrieved OS " .. operating_system .. " could not be identified", "ERROR")
    -- TODO: Better to return an empty string
    return false
  end

  local machine_id = utils.run_terminal_cmd(id_cmd, "Problem retriving machine-id")
  if machine_id then
    return string.gsub(machine_id, "\n$", "")
  else
    return false
  end
end

--- Returns the user that started neovim
---
---@return string|boolean User
M.get_user = function()
  local user = utils.run_terminal_cmd("id -un", "Problem retrieving user name")
  if user then
    return string.gsub(user, "\n$", "")
  else
    return false
  end
end

return M
