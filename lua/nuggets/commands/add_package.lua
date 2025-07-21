local Notify = require("nuggets.notify")
local Window = require("nuggets.window")
local M = {}

--- @class InputOpts
--- Options for configuring the input window.
--- @field title string The title of the search (e.g., "Search package").
--- @field width? number The width of the search UI (default: 40).
--- @field height? number The height of the search UI (default: 1).

--- Create a popup window for user input
--- @param on_confirm fun(input: string) to call when user confirms input
--- @param opts InputOpts with options
--- @option opts.title string title of the popup window
local function input_window(on_confirm, opts)
  local width = opts.width or 40
  local height = opts.height or 1

  local ui = vim.api.nvim_list_uis()[1]
  local win_width = ui.width
  local win_height = ui.height

  local row = math.floor((win_height - height) / 2)
  local col = math.floor((win_width - width) / 2)

  local win = require("plenary.popup").create("", {
    title = opts.title or "",
    style = "minimal",
    borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
    relative = "cursor",
    borderhighlight = "ProjektGunnarBorder",
    titlehighlight = "ProjektGunnarTitle",
    focusable = true,
    width = width,
    height = height,
    line = row,
    col = col,
  })

  vim.cmd("normal A")
  vim.cmd("startinsert")

  vim.keymap.set({ "i", "n" }, "<Esc>", "<cmd>q<CR>", { buffer = 0 })

  vim.keymap.set({ "i", "n" }, "<CR>", function()
    local input = vim.trim(vim.fn.getline("."))
    vim.api.nvim_win_close(win, true)

    on_confirm(input)

    vim.cmd.stopinsert()
  end, { buffer = 0 })
end

---@param args table
---@param on_stdout fun(data: table<string>)
---@param on_exit fun(exit_code: integer)
local function run_async_command(args, on_stdout, on_exit)
  local stderr_output = {}
  local job_id = vim.fn.jobstart(vim.list_extend({ "sh", "-c" }, args), {
    rpc = false,
    stdout_buffered = true,
    stderr_buffered = true,
    on_stderr = function(_, data, _)
      for _, line in ipairs(data) do
        if line ~= "" then
          table.insert(stderr_output, line)
        end
      end
    end,
    on_stdout = function(_, data, _)
      if on_stdout then
        on_stdout(data)
      end
    end,
    on_exit = function(_, exit_code, _)
      if exit_code ~= 0 then
        print(vim.inspect(stderr_output))
      end

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

local function search_for_package(package_name, url)
  local command = "curl '" .. url .. "?q=" .. package_name .. "&prerelease=false&take=20'"
  run_async_command({ command }, function(data)
    local output = table.concat(data, "\n")
    local json_obj = vim.json.decode(output)
    local packages = json_obj.data

    local package_names = {}
    for _, package in ipairs(packages) do
      table.insert(package_names, package.id)
    end

    Window.create_telescope_window(package_names, function(index)
      if index then
        local selected_package = package_names[index]
        local csproj_paths = get_csproj_paths_sync()

        Window.create_telescope_window(csproj_paths, function(csproj_index)
          if not csproj_index then
            Notify.notify_error("No project selected.")
            return
          end

          local selected_csproj = csproj_paths[csproj_index]
          local add_command = string.format('dotnet add "%s" package "%s"', selected_csproj, selected_package)

          run_async_command({ add_command }, function(add_data)
            local add_output = table.concat(add_data, "\n")
            Notify.notify("Package added: " .. selected_package .. "\n" .. add_output)
          end, function(add_exit_code)
            if add_exit_code ~= 0 then
              Notify.notify_error("Failed to add package: " .. selected_package)
            end
          end)
        end)
      end
    end)
  end, function(exit_code)
    if exit_code ~= 0 then
      Notify.notify_error("Failed to search for package: " .. package_name)
    end
  end)
end
local function find_search_query_service(user_input)
  run_async_command({ "curl https://api.nuget.org/v3/index.json" }, function(data)
    local output = table.concat(data, "\n")

    local json_obj = vim.json.decode(output)
    local resources = json_obj.resources

    if not resources or type(resources) ~= "table" then
      Notify.notify_error("The JSON does not contain a 'resources' array or it's not a table.")
      return
    end

    local found_service = nil
    for _, resource in ipairs(resources) do
      if type(resource) == "table" and resource["@type"] then
        if resource["@type"] == "SearchQueryService" then
          found_service = resource
          break
        end
      end
    end
    if found_service then
      search_for_package(user_input, found_service["@id"])
    else
      Notify.notify_error("No SearchQueryService found in NuGet index.")
    end
  end, function(exit_code)
    if exit_code ~= 0 then
      Notify.notify_error("Failed to fetch NuGet index.")
    end
  end)
end

---@param input string the input from the user
local function get_search_input(input)
  find_search_query_service(input)
end

function M.add_package()
  input_window(get_search_input, { title = "Find package" })
end

return M
