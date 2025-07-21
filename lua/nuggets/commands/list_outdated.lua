local M = {}

local Notify = require("nuggets.notify")
local Parser = require("nuggets.parser")
local Window = require("nuggets.window")

---@param args table
---@param on_stdout fun(data: table<string>)
---@param on_exit fun(exit_code: integer)
local function run_async_command(args, on_stdout, on_exit)
  local job_id = vim.fn.jobstart(vim.list_extend({ "sh", "-c" }, args), {
    rpc = false,
    stdout_buffered = true,
    on_stdout = function(_, data, _)
      if on_stdout then
        on_stdout(data)
      end
    end,
    on_exit = function(_, exit_code, _)
      if on_exit then
        on_exit(exit_code)
      end
    end,
  })

  if job_id == 0 then
    vim.notify("Failed to start job: " .. args, vim.log.levels.ERROR)
  end
end

---@param command string the command to execute
local function execute_command(command)
  local handle = Notify.create_progress_handle("Executing command: " .. command)
  local the_output = {}
  run_async_command({ command }, function(data)
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
    the_output = output_lines
  end, function(exit_code)
    if exit_code ~= 0 then
      Notify.progress_report(handle, "Command failed with exit code: " .. exit_code)
    end
    if exit_code == 0 then
      Window.create_results_window(the_output)
    end
    Notify.progress_finish(handle)
  end)
end

function M.list_outdated()
  execute_command("dotnet list package --outdated")
end

return M
