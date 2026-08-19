local nio = require("nio")
local adapter_factory = require("neotest-dotnet")

local fixture_root = vim.fn.getcwd() .. "/tests/fixtures/dotnet"
local fixtures = {
  { framework = "nunit", project = "NUnitFixture", file = "ResultTests.cs" },
  { framework = "xunit", project = "XUnitFixture", file = "ResultTests.cs" },
  { framework = "mstest", project = "MSTestFixture", file = "ResultTests.cs" },
}

local function test_nodes(tree)
  local nodes = {}
  for _, node in tree:iter_nodes() do
    local position = node:data()
    if position.type == "test" then
      nodes[position.name] = position
    end
  end
  return nodes
end

nio.run(function()
  for _, fixture in ipairs(fixtures) do
    local adapter = adapter_factory({ discovery_root = "project" })
    local path = string.format("%s/%s/%s", fixture_root, fixture.project, fixture.file)
    local tree = adapter.discover_positions(path)
    local specs =
      assert(adapter.build_spec({ tree = tree }), "missing " .. fixture.framework .. " spec")
    assert(#specs == 1, "expected one " .. fixture.framework .. " spec")

    vim.fn.system(specs[1].command)
    assert(
      vim.v.shell_error == 1,
      fixture.framework .. " fixture should include one intentional failure"
    )

    local results = adapter.results(specs[1], nil, tree)
    local nodes = test_nodes(tree)
    for name, expected_status in pairs({
      Passing = "passed",
      Failing = "failed",
      Skipped = "skipped",
    }) do
      local node = assert(nodes[name], "missing " .. fixture.framework .. " node " .. name)
      local result =
        assert(results[node.id], "missing " .. fixture.framework .. " result for " .. name)
      assert(
        result.status == expected_status,
        fixture.framework .. " " .. name .. " status mismatch"
      )
    end
  end
end)

print("real dotnet adapter integration: passed")
