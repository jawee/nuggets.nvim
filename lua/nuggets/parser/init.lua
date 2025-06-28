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
    -- trim linebreaks and whitespace
    part = part:gsub("[\n\r]", "")
    -- part = part:gsub("%s+", "")
    table.insert(lines, part)
  end
  return lines
end
function M.parse(str)
  local lines = get_lines_from_string(str)

  -- print(vim.inspect(lines))

  local result = {}
  -- for _, v in ipairs(lines) do
  for i = 1, #lines, 1 do
    local v = lines[i]
    -- print(get_project_name(v))
    if get_project_name(v) then
      local project_name = get_project_name(v)
      result[project_name] = {}

      i = i + 3

      for j = i, #lines, 1 do
        local package_name = get_package_name(lines[j])
        if package_name == nil then
          print("No package name found, breaking")
          i = j
          break
        end
        print("Package name: " .. package_name)
        local package_version = get_package_version(lines[j])
        local package_latest = get_package_latest(lines[j])
        result[project_name][package_name] = {
          Requested = package_version,
          Resolved = package_version,
          Latest = package_latest,
        }
      end
    end
    -- print(v)
    -- for c in str:gmatch "." do
    --   print(c .. "\n")
    -- end
  end

  -- print(vim.inspect(t))
  return result
end

return M
