local nio = require("nio")
local dap = require("dap")

local timeout_ms = 90000
local cleanup_timeout_ms = 5000
local listener_name = "neotest-dotnet-dap-smoke"
local netcoredbg = assert(vim.env.NETCOREDBG, "NETCOREDBG must name the netcoredbg executable")
assert(vim.fn.executable("dotnet") == 1, "dotnet must be available on PATH for the DAP smoke test")
assert(vim.fn.executable(netcoredbg) == 1, "NETCOREDBG must name an executable netcoredbg binary")

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
local breakpoint_hits = 0
local expecting_file_breakpoint = false
local inspection_done = false
local inspection_error
local active_result
local active_session
local completed = false
local success = false
local failure

local function remove_listeners()
  dap.listeners.after.event_initialized[listener_name] = nil
  dap.listeners.after.event_terminated[listener_name] = nil
  dap.listeners.after.event_stopped[listener_name] = nil
end

local function cleanup()
  remove_listeners()
  pcall(dap.clear_breakpoints)
  if active_result then
    pcall(active_result.stop)
  end
  if active_session then
    pcall(active_session.disconnect, active_session, { terminateDebuggee = true })
  end
  pcall(dap.terminate, { all = true, hierarchy = true })
  pcall(dap.close)
end

local function continue_after_inspection(session, thread_id)
  session:request("continue", { threadId = thread_id }, function(err)
    if err and not inspection_error then
      inspection_error = "continue request failed: " .. tostring(err)
    end
  end)
end

dap.listeners.after.event_initialized[listener_name] = function()
  initialized = initialized + 1
end
dap.listeners.after.event_terminated[listener_name] = function()
  terminated = terminated + 1
end
dap.listeners.after.event_stopped[listener_name] = function(session, stopped)
  if not expecting_file_breakpoint or inspection_done or inspection_error then
    return
  end

  breakpoint_hits = breakpoint_hits + 1
  active_session = session
  vim.schedule(function()
    if not vim.wait(5000, function()
      return session.current_frame ~= nil
    end, 25) then
      inspection_error = "breakpoint stopped without a stack frame"
      return
    end

    local frame = session.current_frame
    local thread_id = stopped.threadId or session.stopped_thread_id
    if not thread_id then
      inspection_error = "breakpoint stopped without a thread id"
      return
    end

    session:request("scopes", { frameId = frame.id }, function(scopes_err, scopes_response)
      if scopes_err or not scopes_response or not scopes_response.scopes then
        inspection_error = "scopes request failed: " .. tostring(scopes_err)
        continue_after_inspection(session, thread_id)
        return
      end

      local locals
      for _, scope in ipairs(scopes_response.scopes) do
        if scope.name == "Locals" or not scope.expensive then
          locals = scope
          break
        end
      end
      if not locals or not locals.variablesReference or locals.variablesReference == 0 then
        inspection_error = "no inspectable local scope at breakpoint"
        continue_after_inspection(session, thread_id)
        return
      end

      session:request(
        "variables",
        { variablesReference = locals.variablesReference },
        function(variables_err, response)
          if
            variables_err
            or not response
            or not response.variables
            or #response.variables == 0
          then
            inspection_error = "variables request returned no variables: "
              .. tostring(variables_err)
          else
            inspection_done = true
          end
          continue_after_inspection(session, thread_id)
        end
      )
    end)
  end)
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
    active_result = strategy({
      command = command,
      cwd = vim.fn.getcwd(),
      dap = { adapter_name = "netcoredbg" },
    })
    assert(active_result.result() == 0, fixture.name .. " debug test failed")
    active_result = nil
  end

  local source = vim.fn.getcwd() .. "/tests/fixtures/dotnet/Quoted Project/QuotedTests.cs"
  local adapter = require("neotest-dotnet")({ dotnet_additional_args = { "--no-restore" } })
  local specs =
    assert(adapter.build_spec({ tree = adapter.discover_positions(source), strategy = "dap" }))
  assert(#specs == 1, "expected one file-level DAP spec")
  assert(
    specs[1].strategy == strategy,
    "file-level DAP request did not select the netcoredbg strategy"
  )
  assert(
    specs[1].dap and specs[1].dap.adapter_name == "netcoredbg",
    "file-level DAP spec is missing adapter config"
  )
  specs[1].cwd = vim.fn.getcwd()

  local source_buf = vim.fn.bufadd(source)
  vim.fn.bufload(source_buf)
  vim.api.nvim_set_current_buf(source_buf)
  vim.api.nvim_win_set_cursor(0, { 8, 0 })
  dap.set_breakpoint()

  expecting_file_breakpoint = true
  active_result = strategy(specs[1])
  assert(active_result.result() == 0, "file-level debug test failed")
  active_result = nil
  expecting_file_breakpoint = false

  assert(breakpoint_hits == 1, "expected the file-level DAP breakpoint to be hit once")
  assert(not inspection_error, inspection_error)
  assert(inspection_done, "expected variable inspection at the file-level DAP breakpoint")
  assert(initialized == #fixtures + 1, "expected a DAP session for each method and file request")
  assert(terminated == #fixtures + 1, "expected each DAP session to terminate")
end, function(ok, err)
  completed = true
  success = ok
  failure = err
end)

local finished = vim.wait(timeout_ms, function()
  return completed
end, 50)
if not finished then
  cleanup()
  vim.wait(cleanup_timeout_ms, function()
    return dap.session() == nil
  end, 50)
  error("netcoredbg DAP smoke timed out after " .. timeout_ms .. "ms")
end

cleanup()
assert(success, failure)
print(
  "netcoredbg DAP smoke: method and file-level requests passed with breakpoint variable inspection"
)
vim.cmd("qa!")
