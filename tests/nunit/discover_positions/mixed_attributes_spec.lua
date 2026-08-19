local async = require("nio").tests
local plugin = require("neotest-dotnet")
local DotnetUtils = require("neotest-dotnet.utils.dotnet-utils")
local stub = require("luassert.stub")

local function collect_tests(items, tests)
  for _, item in ipairs(items) do
    if item.type == "test" then
      tests[#tests + 1] = item
    elseif type(item) == "table" then
      collect_tests(item, tests)
    end
  end
end

describe("NUnit mixed test attributes", function()
  require("neotest").setup({
    adapters = {
      require("neotest-dotnet"),
    },
  })

  before_each(function()
    stub(DotnetUtils, "get_test_full_names", function()
      return {
        result = function()
          return {
            output = { "MixedAttributes.Mixed(1)", "MixedAttributes.Mixed(2)" },
            result_code = 0,
          }
        end,
      }
    end)
  end)

  after_each(function()
    DotnetUtils.get_test_full_names:revert()
  end)

  async.it("groups TestCase results under one method", function()
    local positions = plugin.discover_positions("./tests/nunit/specs/mixed_attributes.cs"):to_list()
    local tests = {}
    collect_tests(positions, tests)

    assert.equal(3, #tests)
    assert.equal("Mixed", tests[1].name)
    assert.equal("Mixed(1)", tests[2].name)
    assert.equal("Mixed(2)", tests[3].name)
  end)
end)
