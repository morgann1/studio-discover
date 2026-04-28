# AGENTS.md

## Task Completion Requirements

- `lute run ci` and `lute run test` must pass before considering tasks completed.
- If you touch logic under `plugin/src/`, add or update a Jest spec in `plugin/tests/` and verify it.
- `lute run test` shells out to `run-in-roblox`, which needs a native Roblox Studio install. It does not work under WSL — build there if you like, but run the tests from a native Windows terminal (or open `plugin/tests/build/tests.rbxl` in Studio and run `runTests.server.luau` from the command bar). The command detects WSL and stops after the build with this guidance.

## Project Snapshot

Discover is a Roblox Studio plugin for browsing and installing [Wally](https://wally.run) packages without leaving Studio. It's a pure-Luau alternative to the external Rokit/Rojo/Wally CLI toolchain, aimed at game creators who work entirely inside Studio.

## Core Priorities

1. Performance.
2. Reliability; keep behavior predictable under load and during failures (session restarts, reconnects, partial streams).
3. Long-term maintainability.

If a tradeoff is required, choose correctness and robustness over short-term convenience.

## Maintainability

Maintainability is a first-class priority, not a clean-up step. Hold every change to these rules:

- **Extract shared logic before adding new code.** Before writing functionality, check whether it already exists or can be generalized from existing code. Duplicate logic across multiple files is a code smell.
- **Change existing code.** Don't add a local copy of logic that already lives elsewhere — refactor the shared module so both callers use it. Don't take shortcuts.
- **One file per library function.** Keep utility modules narrow (e.g. `Util/parseSemver.luau`, `Util/formatPackageKey.luau`). Group related single-responsibility modules in a folder (`Util/`, `Common/`) — don't build catch-all `Helpers` / `Utils` modules.
- **Separate modules, not in-file tricks.** Use sibling files to isolate state and responsibilities. Don't fake module boundaries with `do`-blocks or IIFE-style closures.
- **Reduce coupling.** Avoid module-level mutable state that multiple free functions read and write. If a module has two or more independent units of state, split them into sibling modules with explicit APIs.
- **Reduce spaghetti.** Control flow should be readable from a function's arguments and return values, not from tracing side effects through shared state in other helpers.

## Design principles

- **KISS (Keep It Simple, Stupid).** Prefer straightforward solutions. Avoid over-engineering and unnecessary complexity — readable, maintainable code beats clever code.
- **YAGNI (You Aren't Gonna Need It).** Implement only what's needed now. Don't add speculative features, options, or abstractions for hypothetical future needs.
- **SOLID.** Apply the five principles when shaping modules and interfaces:
  - *Single Responsibility* — each module has one reason to change.
  - *Open-Closed* — extend behavior without modifying existing code.
  - *Liskov Substitution* — subtypes honor the contracts of their base types.
  - *Interface Segregation* — callers depend only on the surface they use.
  - *Dependency Inversion* — depend on abstractions, not concrete implementations.

## Style guides

- [docs/process/luau-style.md](docs/process/luau-style.md) — Luau (Roblox plugin).
- [docs/process/react-patterns.md](docs/process/react-patterns.md) — React (Roblox plugin).

## Bumping the version

The plugin version is duplicated across several files and the README's "What's New" highlight reel. When asked to bump the version (e.g. `3.8.0` → `3.8.1`), update **all** of the following in a single commit:

1. `plugin/src/Util/Version.luau` — the runtime version string.
2. `plugin/wally.toml` — `[package].version`.
3. `plugin/wally.lock` — the `morgann1/studio-discover` entry's `version`.
4. `CHANGELOG.md` — add a new `## [X.Y.Z] - YYYY-MM-DD` section above the previous release, move any `[Unreleased]` entries into it, and update the compare links at the bottom (`[Unreleased]` → `compare/vX.Y.Z...HEAD`, plus a new `[X.Y.Z]: .../compare/vPREV...vX.Y.Z` line).
5. `README.md` — update the `### Version X.Y (Latest)` heading **and** the matching ToC anchor (`[Version X.Y (Latest)](#version-xy-latest)`) to reflect the new minor. Refresh the highlight bullets if the release added user-visible changes; for patch releases, only update if the patch is worth surfacing.

Use semver: `MAJOR.MINOR.PATCH`. Dependency bumps and small fixes are PATCH; new user-visible features are MINOR; breaking changes are MAJOR. Commit message format: `chore(release): bump version to X.Y.Z`.

Do **not** create a git tag or push — the user runs the release workflow manually.