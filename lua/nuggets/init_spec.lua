---@diagnostic disable: undefined-field
local eq = assert.are.same

describe("test", function()
  it("should pass", function()
    eq(1, 1)
  end)
end)
