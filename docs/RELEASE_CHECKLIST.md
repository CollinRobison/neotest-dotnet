# Release Checklist

## Before release

- [ ] Fetch `upstream` and review the diff against this fork.
- [ ] Confirm supported Neovim, Neotest, Tree-sitter, and .NET versions.
- [ ] Run `make test-ci`.
- [ ] Run `make integration-test` with a supported `dotnet` SDK on `PATH`.
- [ ] Run `make lint`.
- [ ] Verify NUnit, xUnit, and MSTest discovery and result mapping.
- [ ] Verify a real DAP session through `netcoredbg`, including failure and clean termination.
- [ ] Update `CHANGELOG.md` and user-facing documentation.
- [ ] Update the dotfiles lockfile to the tested fork commit.

## Publish

- [ ] Merge a green pull request to `main`.
- [ ] Create and verify the release/tag generated from `main`.
- [ ] Smoke-test installation from `CollinRobison/neotest-dotnet`.
- [ ] Record any deferred compatibility or framework issues.
