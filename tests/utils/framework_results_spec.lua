local lib = require("neotest.lib")
local stub = require("luassert.stub")
local Tree = require("neotest.types").Tree

local frameworks = {
  { name = "nunit", module = require("neotest-dotnet.nunit") },
  { name = "xunit", module = require("neotest-dotnet.xunit") },
  { name = "mstest", module = require("neotest-dotnet.mstest") },
}

describe("TRX result collection", function()
  local trx = table.concat(vim.fn.readfile("./tests/fixtures/results/statuses.trx"), "\n")
  local result_path = "./tests/fixtures/results/statuses.trx"

  before_each(function()
    stub(lib.files, "read", function(path)
      if path == result_path then
        return trx
      end
      return ""
    end)
  end)

  after_each(function()
    lib.files.read:revert()
  end)

  for _, framework in ipairs(frameworks) do
    it("collects singleton and multiple " .. framework.name .. " results", function()
      local path = "./tests/fixtures/results/statuses.cs"
      local function test_node(name)
        local node_name = framework.name == "xunit" and "Fixtures.ResultTests." .. name or name
        return {
          id = path .. "::Fixtures::ResultTests::" .. name,
          name = node_name,
          path = path,
          range = { 1, 0, 2, 0 },
          type = "test",
          framework = framework.name,
        }
      end

      local tree = Tree.from_list({
        {
          id = path,
          name = "statuses.cs",
          path = path,
          range = { 0, 0, 10, 0 },
          type = "file",
        },
        {
          {
            id = path .. "::Fixtures",
            name = "Fixtures",
            path = path,
            range = { 1, 0, 10, 0 },
            type = "namespace",
            framework = framework.name,
          },
          {
            {
              id = path .. "::Fixtures::ResultTests",
              name = "ResultTests",
              path = path,
              range = { 1, 0, 10, 0 },
              type = "namespace",
              framework = framework.name,
              is_class = true,
            },
            { test_node("Passed") },
            { test_node("Failed") },
            { test_node("Skipped") },
          },
        },
      }, function(position)
        return position.id
      end)

      local results = framework.module.generate_test_results(result_path, tree, "context")

      assert.equal("passed", results[path .. "::Fixtures::ResultTests::Passed"].status)
      assert.equal("failed", results[path .. "::Fixtures::ResultTests::Failed"].status)
      assert.equal("skipped", results[path .. "::Fixtures::ResultTests::Skipped"].status)
      assert.same(
        { message = "Fixtures.ResultTests.Failed: assertion failed\nat Fixtures.ResultTests.Failed()" },
        results[path .. "::Fixtures::ResultTests::Failed"].errors[1]
      )
    end)
  end
end)
