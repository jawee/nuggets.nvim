local Commands = require("nuggets.commands")
local Window = require("nuggets.window")

local M = {}

function M.setup(_) end

---@type table<string, fun()>
local commands = {
  ["List outdated"] = Commands.list_outdated,
  ["Add Package"] = Commands.add_nuget,
  ["Update All Packages"] = Commands.update_all,
}

function M.openMainMenu()
  local options = commands or {}

  local selections = {}
  for k in pairs(options) do
    table.insert(selections, k)
  end

  ---@param row integer
  local function select_current_line(row)
    local choice = selections[row]
    if choice then
      M.executeCommand(choice)
    end
  end

  Window.create_telescope_window(selections, select_current_line, nil, "Available Commands")
end

---@param command string the command to execute
function M.executeCommand(command)
  local cmd = commands[command]
  cmd()
end

vim.api.nvim_create_user_command("Nuggets", function()
  M.openMainMenu()
end, { nargs = "*", desc = "Nuggets plugin" })

return M
