local Parser = require("nuggets.parser")
---@diagnostic disable: undefined-field
local eq = assert.are.same

describe("parse", function()
  it("should return an empty table for an empty string", function()
    local result = Parser.parse("")
    eq(result, {})
  end)
  it("should return the project with an empty table for a string with no packages", function()
    local str = [[
       Project `Authenticatly` has the following updates to its packages
    ]]
    local expected = {
      Authenticatly = {},
    }

    local result = Parser.parse(str)
    eq(result, expected)
  end)
  it("should parse the string correctly", function()
    local expected = {
      ExampleApi = {},
      Authenticatly = { ["System.IdentityModel.Tokens.Jwt"] = { Requested = "8.12.0", Resolved = "8.12.0", Latest = "8.12.1" } },
    }

    local input = [[
      The following sources were used:
         https://api.nuget.org/v3/index.json

      The given project `ExampleApi` has no updates given the current sources.
      Project `Authenticatly` has the following updates to its packages
         [net9.0]:
         Top-level Package                      Requested   Resolved   Latest
         > System.IdentityModel.Tokens.Jwt      8.12.0      8.12.0     8.12.1
      ]]

    local result = Parser.parse(input)
    eq(result, expected)
  end)
  it("should parse multiple projects correctly", function()
    local expected = {
      ExampleApi = {},
      Authenticatly = { ["System.IdentityModel.Tokens.Jwt"] = { Requested = "8.12.0", Resolved = "8.12.0", Latest = "8.12.1" } },
      ["Authenticatly.IntegrationTests"] = {
        ["MSTest.TestAdapter"] = { Requested = "3.9.2", Resolved = "3.9.2", Latest = "3.9.3" },
        ["MSTest.TestFramework"] = { Requested = "3.9.2", Resolved = "3.9.2", Latest = "3.9.3" }
      },
    }

    local input = [[
      The following sources were used:
         https://api.nuget.org/v3/index.json

      The given project `ExampleApi` has no updates given the current sources.
      Project `Authenticatly` has the following updates to its packages
         [net9.0]:
         Top-level Package                      Requested   Resolved   Latest
         > System.IdentityModel.Tokens.Jwt      8.12.0      8.12.0     8.12.1

      Project `Authenticatly.IntegrationTests` has the following updates to its packages
         [net9.0]:
         Top-level Package           Requested   Resolved   Latest
         > MSTest.TestAdapter        3.9.2       3.9.2      3.9.3
         > MSTest.TestFramework      3.9.2       3.9.2      3.9.3
      ]]

    local result = Parser.parse(input)
    eq(result, expected)
  end)
end)

describe("get_project_name", function()
  it("should extract project name from line", function()
    local line = " Project `Authenticatly` has the following updates to its packages"
    local expected = "Authenticatly"
    local result = Parser._get_project_name(line)

    eq(result, expected)
  end)
  it("should extract project name from line with dot in name", function()
    local line = "Project `Authenticatly.IntegrationTests` has the following updates to its packages"
    local expected = "Authenticatly.IntegrationTests"
    local result = Parser._get_project_name(line)

    eq(result, expected)
  end)

  it("should return nil if no project name is found", function()
    local line = "No project name here"
    local result = Parser._get_project_name(line)

    eq(result, nil)
  end)
end)

describe("get_package_name", function()
  it("should extract package name from line", function()
    local line = "   > System.IdentityModel.Tokens.Jwt      8.12.0      8.12.0     8.12.1"
    local expected = "System.IdentityModel.Tokens.Jwt"
    local result = Parser._get_package_name(line)

    eq(result, expected)
  end)

  it("should return nil if no package name is found", function()
    local line = "No package name here"
    local result = Parser._get_package_name(line)

    eq(result, nil)
  end)
end)

describe("get_package_version", function()
  it("should extract package version from line", function()
    local line = "   > System.IdentityModel      24.1.0      25.2.0     26.3.1"
    local expected = "24.1.0"
    local result = Parser._get_package_version(line)

    eq(result, expected)
  end)
  it("should extract package version from line", function()
    local line = "   > System.IdentityModel.Tokens.Jwt      6.12.0      7.12.0     8.12.1"
    local expected = "6.12.0"
    local result = Parser._get_package_version(line)

    eq(result, expected)
  end)

  it("should return nil if no version is found", function()
    local line = "No version here"
    local result = Parser._get_package_version(line)

    eq(result, nil)
  end)
end)

describe("get_package_latest", function()
  it("should extract latest package version from line", function()
    local line = "   > System.IdentityModel.Tokens.Jwt      6.12.0      7.12.0     8.12.1"
    local expected = "8.12.1"
    local result = Parser._get_package_latest(line)

    eq(result, expected)
  end)

  it("should return nil if no latest version is found", function()
    local line = "No latest version here"
    local result = Parser._get_package_latest(line)

    eq(result, nil)
  end)
end)
