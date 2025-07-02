local Command = require("nuggets.command")
local Notify = require("nuggets.notify")
local Parser = require("nuggets.parser")
local Window = require("nuggets.window")

local M = {}

function M.setup(_) end

---@type table<string, string>
local commands = {
  ["List outdated"] = "dotnet list package --outdated",
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

  Window.createTelescopeWindow(selections, select_current_line, nil, "Available Commands")
end

---@param command string the command to execute
local function executeCommand(command)
  local handle = Notify.create_progress_handle("Executing command: " .. command)
  Command.run_async_command({ command }, function(data)
    local output = table.concat(data, "\n")

    local objs = Parser.parse(output)

    local output_lines = {}
    for project, packages in pairs(objs) do
      table.insert(output_lines, "Project: " .. project)
      if next(packages) == nil then
        table.insert(output_lines, "  No updates available.")
      else
        for package, versions in pairs(packages) do
          table.insert(
            output_lines,
            string.format("  %s: Requested: %s, Latest: %s", package, versions.Requested, versions.Latest)
          )
        end
      end
      table.insert(output_lines, "")
    end

    Window.createResultsWindow(output_lines)
  end, function(exit_code)
    if exit_code ~= 0 then
      Notify.progress_update(handle, "Command failed with exit code: " .. exit_code)
    end
    Notify.progress_finish(handle)
  end)
end

---@param command string the command to execute
function M.executeCommand(command)
  local cmd = commands[command]

  executeCommand(cmd)
end

vim.api.nvim_create_user_command("Nuggets", function()
  M.openMainMenu()
end, { nargs = "*", desc = "Nuggets plugin" })

return M
