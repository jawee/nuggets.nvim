local M = {}

local Notify = require("nuggets.notify")
local Parser = require("nuggets.parser")

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

local function get_csproj_paths_sync()
  local command = "dotnet sln list"

  local stdout_lines = vim.fn.systemlist(command)

  if #stdout_lines == 0 then
    Notify.notify_error("No projects found in solution. Make sure you are in a valid .sln directory.")
    return {}
  end

  local csproj_paths = {}

  for _, raw_line in ipairs(stdout_lines) do
    local line = raw_line:gsub("[\r\n%s]*$", "")
    if string.find(line, "%.csproj$") then
      table.insert(csproj_paths, line)
    end
  end

  if #csproj_paths == 0 and #stdout_lines == 0 then
    Notify.notify_error("No projects found in solution. Make sure you are in a valid .sln directory.")
  end

  return csproj_paths
end

---@param command string the command to execute
local function execute_command(command)
  local handle = Notify.create_progress_handle("Executing command: " .. command)
  local csproj_paths = get_csproj_paths_sync()

  local csproj_map = {}
  for _, path in ipairs(csproj_paths) do
    local project_name = path:match("([^/\\]+)%.csproj$")
    if project_name then
      csproj_map[project_name] = path
    end
  end

  local command_output = ""
  run_async_command({ command }, function(data)
    command_output = table.concat(data, "\n")
  end, function(exit_code)
    if exit_code ~= 0 then
      Notify.progress_report(handle, "Command failed with exit code: " .. exit_code)
    else
      local projs = Parser.parse(command_output)

      Notify.progress_report(handle, "Updating packages..")
      for project, packages in pairs(projs) do
        if csproj_map[project] then
          local csproj_path = csproj_map[project]
          for package, _ in pairs(packages) do
            local add_command = string.format('dotnet add "%s" package "%s"', csproj_path, package)
            run_async_command({ add_command }, function() end, function() end)

            vim.fn.systemlist(add_command)
          end
        end
      end
      Notify.progress_report(handle, "Packages updated successfully.")
    end
    Notify.progress_finish(handle)
  end)
end

function M.update_all()
  execute_command("dotnet list package --outdated")
end

return M
