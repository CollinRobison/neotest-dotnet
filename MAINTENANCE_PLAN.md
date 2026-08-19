# neotest-dotnet Maintenance Plan

This fork is intended to keep the `neotest-dotnet` adapter usable with current Neovim, Neotest, Tree-sitter, and .NET releases while preserving the upstream adapter's useful behavior.

## Starting point

- Fork: `CollinRobison/neotest-dotnet`
- Upstream: `Issafalcon/neotest-dotnet`
- Baseline: upstream `main` at the fork's current `HEAD`
- Upstream's latest tagged release: `v1.7.0` (2024-12-27)
- License: MIT; retain the upstream copyright and license text
- Current Neovim consumer: Neovim `0.12.4`
- Current .NET SDK: .NET `10.0.302`

The fork currently contains the upstream Lua adapter, Tree-sitter queries, DAP strategy, Plenary tests, GitHub Actions workflow, and Makefile. The existing test suite is the foundation for the maintenance work.

## Handoff status

The first maintenance pass is implemented on the `maintenance/baseline` branch. The latest committed change is `a2d2fac` (`support solution file roots`). The branch is pushed to the fork and has an open draft pull request.

### Completed

- Added and fetched the `upstream` remote; current upstream `main` was reviewed against the fork baseline.
- Fixed Neovim 0.12 and current Tree-sitter query capture compatibility, including `iter_matches` capture lists.
- Kept compatibility with the legacy nvim-treesitter API and added parser installation support for the current API.
- Added CI coverage for Neovim 0.10.x, 0.12.4, and nightly. Neovim 0.10.x uses nvim-treesitter `v0.9.3`; newer versions use current `master`.
- Added support and regression coverage for MSTest `DataRow` discovery and custom method attributes.
- Fixed MSTest file-level filters and NUnit mixed `[Test]`/`[TestCase]` discovery.
- Fixed singleton TRX result parsing, result identity matching, unknown outcomes, skipped results, and TRX output exposure.
- Added discovery behavior for files without test attributes and actionable errors when a runnable test has no `.csproj`.
- Added coverage for runsettings, additional `dotnet test` arguments, `.slnx` roots, empty files, framework discovery, and result states.
- Added clear errors for missing `nvim-dap` or an unconfigured DAP adapter.
- Added a real .NET integration target that runs NUnit, xUnit, and MSTest projects through adapter discovery, `build_spec`, and `results`; it validates passed, failed, and skipped result states and file-scoped MSTest identities.
- Verified live DAP attach smoke tests for NUnit, xUnit, and MSTest passing-method sessions through `nvim-dap` and `netcoredbg`; each initializes, exits, and terminates cleanly.
- Local `make test` and `make lint` pass. GitHub CI passes the compatibility matrix and lint job.

### Still required

- Expand the real fixture matrix for Phase 2 layouts: solutions with multiple projects, nested projects, `global.json`, `Directory.Build.props`, multiple target frameworks, and `.runsettings`.
- Extend end-to-end result coverage for stdout/stderr, exceptions, unusual display names, no-match runs, and parameterized results.
- Complete DAP validation with `netcoredbg`: NUnit, xUnit, and MSTest sessions; file/method requests; breakpoints; variables; output; failed attach; clean termination; and parameterized tests.
- Review temporary result/output cleanup and command argument quoting with real projects.
- Update fork-facing README links and documentation, add a changelog entry, assign the first maintained version, and define the release checklist.

The compatibility work is therefore in good shape, but the first maintained release is not ready until the real .NET integration and DAP work are complete.

## Goals

1. Keep test discovery and result collection working with maintained Neovim and Neotest versions.
2. Support NUnit, xUnit, and MSTest reliably for common project layouts.
3. Preserve `dotnet test` as the execution backend instead of reimplementing the .NET test platform prematurely.
4. Make solution/project selection, framework detection, runsettings, filters, and diagnostics predictable.
5. Keep debugging through `nvim-dap` and `netcoredbg` isolated from test discovery changes.
6. Make regressions reproducible with small C# fixtures and automated tests.
7. Make upstream synchronization and release maintenance routine.

## Known risks to address

The upstream project currently advertises that it is looking for maintainers. Its open issues include problems with:

- Framework detection on Neovim 0.11+ and newer Tree-sitter capture behavior.
- Compatibility with newer Neotest versions.
- Multiple adapters reporting `No test found`.
- NUnit parameterized tests and mixed `[Test]`/`[TestCase]` methods.
- NUnit and MSTest Tree-sitter queries.
- Empty or incorrectly nested summaries.
- Result status mismatches and slow discovery.
- Integrating more directly with VSTest for performance and coverage.

These issues should be reproduced against Neovim 0.12 before making broad changes.

## Phase 1: Establish the maintenance baseline

- Add the upstream repository as a Git remote named `upstream`.
- Record the upstream commit and the fork's first maintained version.
- Run the existing test suite with `make test-ci`.
- Run `make lint`.
- Test the adapter against the Neotest revision used by the Neovim configuration.
- Test with the C# Tree-sitter parser used by the current Neovim setup.
- Capture failures as focused issues or regression tests before changing implementation code.

Required baseline commands:

```bash
make test-ci
make lint
nvim --version
```

The fork's current CI only tests Neovim 0.10.x and nightly. The matrix should be expanded to include the maintained stable versions used by the fork, especially Neovim 0.12.

## Phase 2: Strengthen the test fixture matrix

Add small fixtures and unit tests for:

### Project layout

- A single `.csproj` test project.
- A solution containing multiple test projects.
- Nested project directories.
- A solution root with projects in separate child directories.
- SDK-style projects using `global.json`.
- Projects using `Directory.Build.props`.
- Projects with multiple target frameworks.
- Projects with `.runsettings` files.

### Frameworks

- NUnit.
- xUnit.
- MSTest.

### C# syntax and discovery

- File-scoped and block-scoped namespaces.
- Classes with and without framework class attributes.
- Nested classes.
- Methods with ordinary test attributes.
- Inline parameterized tests.
- Dynamically parameterized tests.
- Custom test attributes.
- Custom display names.
- Multiple test methods in one file.
- Files with no tests.

### Execution and results

- Passing tests.
- Failing tests.
- Skipped tests.
- Tests with standard output and error output.
- Tests that throw exceptions.
- Tests with long or unusual display names.
- Test runs with no matching tests.

Every bug fix should add a regression fixture before or alongside the implementation change.

## Phase 3: Neovim and Neotest compatibility

Audit the adapter against current APIs rather than adding compatibility shims blindly.

- Review all Tree-sitter query captures and `iter_matches` handling.
- Confirm behavior with Neovim 0.10, 0.11, and 0.12 where practical.
- Confirm behavior with the current Neotest API and `nvim-nio`.
- Remove deprecated Neovim APIs when the supported-version policy allows it.
- Keep compatibility branches small and documented when older supported versions require them.
- Ensure adapter setup does not claim C# buffers belonging to unrelated adapters.
- Verify that root detection and framework detection remain deterministic when multiple adapters are configured.

The first compatibility target is Neovim 0.12. Older versions should remain supported only if the maintenance cost is small and CI can validate them.

## Phase 4: Improve framework and project detection

Improve detection in this order:

1. Find the nearest relevant solution or project root.
2. Select a solution when configured and available; otherwise select a project.
3. Detect the test framework from project metadata and source attributes.
4. Use framework-specific Tree-sitter queries for precise positions.
5. Fall back to conservative source inspection when metadata is incomplete.
6. Return an actionable diagnostic when no compatible test project or framework is found.

Detection should not silently choose an unrelated project in a multi-project solution.

The public configuration should continue to support explicit choices such as:

```lua
require("neotest-dotnet")({
  discovery_root = "project", -- or "solution"
})
```

Any new configuration should have a documented default and a fixture test.

## Phase 5: Improve command construction and result parsing

Keep `dotnet test` as the default runner and improve the boundaries around it.

- Construct filters from stable fully-qualified names where possible.
- Keep the existing parameterized-test fallback behavior, but document its precision limits.
- Preserve adapter-owned `--logger`, `--results-directory`, and filter arguments.
- Support project-specific additional arguments without allowing them to corrupt result collection.
- Make `global.json`, target framework, runtime, solution, project, and runsettings behavior explicit.
- Validate TRX parsing for every supported result state.
- Preserve useful stdout/stderr and failure messages.
- Clean up temporary result directories reliably after success and failure.
- Return nonzero process failures as test failures rather than discovery failures when possible.

A future VSTest protocol integration may improve performance and test identity, but it should be a separate design project after the `dotnet test` path is stable.

## Phase 6: Debugging support

Keep debugging compatible with the existing Neotest DAP strategy:

- `nvim-dap` owns the DAP client and adapter configuration.
- `netcoredbg` owns the .NET debugging protocol.
- The adapter starts the test host with `VSTEST_HOST_DEBUG` and attaches through DAP.
- Test discovery and DAP launch configuration remain separate concerns.

Add regression coverage for:

- NUnit, xUnit, and MSTest debug sessions.
- Method and file-level debug requests.
- Breakpoint hits.
- Variable inspection.
- Test output while attached.
- Clean termination and failed attach.
- Parameterized-test debug behavior.

The adapter should report a clear error when `netcoredbg` or its configured DAP adapter is unavailable.

## Phase 7: CI and release maintenance

Update GitHub Actions to:

- Test maintained Neovim versions, including 0.12.
- Test the current stable Neovim release and nightly.
- Run Lua formatting checks.
- Run the full Plenary test suite.
- Cache dependencies safely.
- Keep action versions current.
- Run documentation checks if generated documentation is enabled.

Add a release checklist:

1. Sync upstream changes.
2. Review Neovim, Neotest, Tree-sitter, and .NET compatibility.
3. Run lint and the full fixture suite.
4. Test a real NUnit, xUnit, and MSTest project.
5. Update `CHANGELOG.md`.
6. Tag a release.
7. Update the Neovim dotfiles lockfile to the tested fork commit.

Do not automatically publish a release solely because upstream changed. Every release must pass the fork's compatibility matrix.

## Out of scope for the first update

- Replacing `dotnet test` with a complete custom VSTest protocol client.
- Supporting F# before a reliable C#-compatible Tree-sitter strategy exists.
- Reimplementing `netcoredbg`.
- Adding framework-specific behavior without a fixture.
- Breaking existing configuration names for cosmetic cleanup.

## Definition of done

The first maintained release is ready when:

- Neovim 0.12 passes the full automated suite.
- NUnit, xUnit, and MSTest discovery work for ordinary and parameterized cases.
- Single-test, file, project, solution, and suite runs produce correct results.
- Failure output points to the correct source location.
- `.runsettings` and documented additional arguments work.
- DAP test debugging works when `netcoredbg` is installed.
- Missing tools produce actionable errors.
- CI tests the supported Neovim versions.
- The Neovim dotfiles configuration can pin and consume the fork reproducibly.

## Related documentation

- Upstream: <https://github.com/Issafalcon/neotest-dotnet>
- Neotest: <https://github.com/nvim-neotest/neotest>
- Debug Adapter Protocol: <https://microsoft.github.io/debug-adapter-protocol/specification>
- NetCoreDbg: <https://github.com/Samsung/netcoredbg>
