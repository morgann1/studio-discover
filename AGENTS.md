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