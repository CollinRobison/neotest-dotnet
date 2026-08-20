local async = require("nio").tests
local plugin = require("neotest-dotnet")

describe("discovery without framework attributes", function()
  async.it("returns a file position without running dotnet discovery", function()
    local positions = plugin.discover_positions("./tests/xunit/specs/no_tests.cs"):to_list()

    assert.same({
      {
        id = "./tests/xunit/specs/no_tests.cs",
        name = "no_tests.cs",
        path = "./tests/xunit/specs/no_tests.cs",
        range = { 0, 0, 8, 0 },
        type = "file",
      },
    }, positions)
  end)
end)
