local M = {}

local function get_project_name(line)
  local project_name = line:match("`([%w.]+)`")
  return project_name
end

M._get_project_name = get_project_name

local function get_package_name(line)
  local package_name = line:match(">%s*([%w%.%-]+)")

  return package_name
end

M._get_package_name = get_package_name

local function get_package_version(line)
  local version = line:match(">%s*[%w%.%-]+%s+(%d+%.%d+%.%d+)")

  return version
end

M._get_package_version = get_package_version

local function get_package_latest(line)
  local latest = line:match(">%s*[%w%.%-]+%s+%d+%.%d+%.%d+%s+%s+%d+%.%d+%.%d+%s+(%d+%.%d+%.%d+)")

  return latest
end

M._get_package_latest = get_package_latest

local get_lines_from_string = function(str)
  local lines = {}
  for part in string.gmatch(str, "([^\n]+)") do
    part = part:gsub("[\n\r]", "")
    table.insert(lines, part)
  end
  return lines
end

--- @param str string
--- @return table<string, table<string, {Requested: string, Latest: string}>>
function M.parse(str)
  local lines = get_lines_from_string(str)

  local result = {}
  local i = 0
  while i < #lines do
    i = i + 1
    local v = lines[i]
    if get_project_name(v) then
      local project_name = get_project_name(v)
      result[project_name] = {}

      for j = i + 3, #lines do
        local package_name = get_package_name(lines[j])
        if package_name == nil then
          break
        end
        local package_version = get_package_version(lines[j])
        local package_latest = get_package_latest(lines[j])
        result[project_name][package_name] = {
          Requested = package_version,
          Latest = package_latest,
        }
      end
    end
  end

  return result
end

return M
