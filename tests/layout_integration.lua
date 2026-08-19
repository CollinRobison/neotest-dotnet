local nio = require("nio")
local Tree = require("neotest.types").Tree
local adapter_factory = require("neotest-dotnet")

local root = vim.fn.getcwd() .. "/tests/fixtures/dotnet/LayoutMatrix"
local top_level = root .. "/TopLevelTests"
local nested = root .. "/nested"
local nested_project = nested .. "/NestedTests"
local adapter = adapter_factory({ discovery_root = "solution" })

local tree = Tree.from_list({
  { id = root, name = "LayoutMatrix", path = root, type = "dir" },
  { id = top_level, name = "TopLevelTests", path = top_level, type = "dir" },
  {
    { id = nested, name = "nested", path = nested, type = "dir" },
    { id = nested_project, name = "NestedTests", path = nested_project, type = "dir" },
  },
}, function(position)
  return position.id
end)

assert(adapter.root(nested_project .. "/NestedTests.cs") == root, "solution root mismatch")
local completed, success, failure = false, false, nil
nio.run(function()
  vim.g.neotest_dotnet_runsettings_path = root .. "/test.runsettings"
  local specs = assert(adapter.build_spec({ tree = tree }))
  assert(#specs == 2, "expected both layout projects")
  for _, spec in ipairs(specs) do
    assert(spec.command:find("%-%-settings", 1, false), "missing runsettings")
    vim.fn.system(spec.command)
    assert(vim.v.shell_error == 0, "layout test project failed")
  end

  for _, source in ipairs({
    top_level .. "/TopLevelTests.cs",
    nested_project .. "/NestedTests.cs",
  }) do
    local discovered = adapter.discover_positions(source)
    local spec = assert(adapter.build_spec({ tree = discovered }))[1]
    vim.fn.system(spec.command)
    assert(vim.v.shell_error == 0, "layout source test failed")

    local passing
    for _, node in discovered:iter_nodes() do
      local position = node:data()
      if position.type == "test" and position.name == "Passing" then
        passing = position
        break
      end
    end
    assert(passing, "layout source did not discover Passing")
    local result = adapter.results(spec, nil, discovered)[passing.id]
    assert(result and result.status == "passed", "layout source result was not passed")
  end

  vim.g.neotest_dotnet_runsettings_path = nil
end, function(ok, err)
  completed, success, failure = true, ok, err
end)
assert(
  vim.wait(600000, function()
    return completed
  end, 50),
  "layout integration timed out"
)
assert(success, failure)
print("real dotnet layout integration: passed")
