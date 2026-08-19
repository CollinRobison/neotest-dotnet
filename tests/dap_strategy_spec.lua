describe("netcoredbg strategy configuration", function()
  local original_dap
  local original_preload

  before_each(function()
    original_dap = package.loaded.dap
    original_preload = package.preload.dap
    package.loaded.dap = nil
    package.preload.dap = nil
  end)

  after_each(function()
    package.loaded.dap = original_dap
    package.preload.dap = original_preload
  end)

  it("reports a missing nvim-dap dependency", function()
    local strategy = require("neotest-dotnet.strategies.netcoredbg")
    assert.has_error(function()
      strategy({})
    end, "neotest-dotnet: nvim-dap is required for debug strategy")
  end)

  it("reports an unconfigured dap adapter", function()
    package.preload.dap = function()
      return { adapters = {} }
    end
    local strategy = require("neotest-dotnet.strategies.netcoredbg")
    assert.has_error(function()
      strategy({ dap = { adapter_name = "netcoredbg" } })
    end, "neotest-dotnet: configure the nvim-dap adapter 'netcoredbg' first")
  end)
end)
