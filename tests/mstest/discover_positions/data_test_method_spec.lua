local async = require("nio").tests
local plugin = require("neotest-dotnet")({
  custom_attributes = {
    mstest = { "CustomTestMethod" },
  },
})

local function collect_tests(items, tests)
  for _, item in ipairs(items) do
    if item.type == "test" then
      tests[#tests + 1] = item.name
    elseif type(item) == "table" then
      collect_tests(item, tests)
    end
  end
end

describe("MSTest discovery", function()
  require("neotest").setup({
    adapters = {
      plugin,
    },
  })

  async.it("discovers DataRow cases and ordinary TestMethod tests", function()
    local positions = plugin.discover_positions("./tests/mstest/specs/data_test_method.cs"):to_list()
    local tests = {}
    collect_tests(positions, tests)
    table.sort(tests)

    assert.same({ "Adds", "Adds(1)", "Adds(2)", "Smoke" }, tests)
  end)

  async.it("discovers configured custom test attributes", function()
    local positions = plugin.discover_positions("./tests/mstest/specs/custom_attribute.cs"):to_list()
    local tests = {}
    collect_tests(positions, tests)

    assert.same({ "CustomTest" }, tests)
  end)
end)
