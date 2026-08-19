local nio = require("nio")
local dap = require("dap")

local netcoredbg = assert(vim.env.NETCOREDBG, "NETCOREDBG must name the netcoredbg executable")
dap.adapters.netcoredbg = {
  type = "executable",
  command = netcoredbg,
  args = { "--interpreter=vscode" },
}

local fixtures = {
  { name = "NUnit", project = "NUnitFixture", filter = "DotnetFixtures.NUnit.ResultTests.Passing" },
  { name = "xUnit", project = "XUnitFixture", filter = "DotnetFixtures.XUnit.ResultTests.Passing" },
  {
    name = "MSTest",
    project = "MSTestFixture",
    filter = "DotnetFixtures.MSTest.ResultTests.Passing",
  },
}

local initialized = 0
local terminated = 0
dap.listeners.after.event_initialized["neotest-dotnet-dap-smoke"] = function()
  initialized = initialized + 1
end
dap.listeners.after.event_terminated["neotest-dotnet-dap-smoke"] = function()
  terminated = terminated + 1
end

nio.run(function()
  local strategy = require("neotest-dotnet.strategies.netcoredbg")
  for _, fixture in ipairs(fixtures) do
    local command = string.format(
      "dotnet test tests/fixtures/dotnet/%s/%s.csproj --no-restore --filter 'FullyQualifiedName~%s' --logger 'console;verbosity=normal'",
      fixture.project,
      fixture.project,
      fixture.filter
    )
    local result = strategy({
      command = command,
      cwd = vim.fn.getcwd(),
      dap = { adapter_name = "netcoredbg" },
    })
    assert(result.result() == 0, fixture.name .. " debug test failed")
  end

  assert(initialized == #fixtures, "expected a DAP session for each fixture")
  assert(terminated == #fixtures, "expected each DAP session to terminate")
  print("netcoredbg DAP smoke: NUnit, xUnit, and MSTest passed")
  vim.cmd("qa!")
end)
