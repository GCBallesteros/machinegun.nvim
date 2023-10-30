local M = {}

M.run_terminal_cmd = function(command, error_message)
  local f = io.popen(command)
  if not f then
    vim.notify("[Machinegun] " .. error_message)
    return false
  end
  local out = f:read "*a" or ""
  f:close()
  return out
end

return M
