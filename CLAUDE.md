# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Rules
- **Comments**: Never add comments to my code.
- **Code Style**: Only write code that is self-explanatory.
- **Improvements**: Do not add comments explaining your changes.

## Code style guide

Follow these principles when writing or modifying Luau code in this project. Use `camelCase` for variables and functions, `PascalCase` for classes/types.

1. **Use descriptive, obvious names.**
    - No abbreviations; use full English words. `player` not `plr`.
    - Name things directly. `wasCalled` not `hasBeenCalled`. `notify` not `doNotification`.
    - Booleans read as yes/no questions. `isFirstRun` not `firstRun`.
    - Functions use verb forms. `increment` not `plusOne`. `unzip` not `filesFromZip`.
    - Event handlers express when they run. `onClick` not `click`.
    - Prefer positive form. `isFlying` not `isNotFlying`. `late` not `notOnTime`. Lead with positive conditionals; avoid `if not x then ... else ... end`. Use `missingValue` instead of `not hasValue`.

2. **Function signatures should be obvious at the call site.**
    - Avoid boolean arguments that change behavior.
    - Avoid `nil` arguments. Use an options dictionary as the last parameter instead.

3. **Write less code.**
    - Be concise: fewer lines means fewer places for bugs to hide.
    - Use well-supported open source libraries when possible.
    - Omit needless variables. Don't name values you only use once.
    - Write good abstractions. Don't repeat yourself.

4. **Colocate code by feature, not by type.**
    - Each feature manages its own state and explicitly defines methods to access and change it.

5. **One job per function. Keep code reusable.**
    - Don't combine loading and calculating in one function.
    - Prefer functions with few or no side effects.

6. **Avoid features and patterns that consistently lead to mistakes.**

7. **Prefer stateful instances (classes) over excessive data structuring.**
    - Avoid global state.
    - Prefer composition over inheritance.
    - Ensure anything created can also be cleaned up (event listeners, instance-bound state).
    - Prefer getter/setter functions for public access to private state.

8. **Prefer generic solutions over specific ones.** When a generic solution doesn't fit, write parallel code for parallel concepts.

9. **Optimize for reading, not writing.**
    - Be idiomatic. Follow convention.
    - Code should not be surprising.

10. **Exceptions should be exceptional.**
    - Don't use errors as standard control flow.
    - Return a success value or status. Reserve errors for unrecoverable states.

11. **Code should be boring.**

12. **Untestable code is bad code.**

## What this is

Studio Discover is a Roblox Studio plugin (Luau + React) that lets users browse, install, and manage Wally packages without leaving Studio. The plugin talks directly to the Wally registry HTTP API and writes installed packages into `ReplicatedStorage.Packages` / `ServerStorage.ServerPackages` as alias `ModuleScript`s.

## Toolchain & commands

Toolchain is pinned via `rokit.toml` (run `rokit install` once after cloning). Build / dev workflows are Lune scripts under `.lune/commands/`, invoked from the repo root:

- `lune run setup` — first-time setup: codegen + install Wally packages, package types, and Foundation (downloaded from a pinned Roblox version), then apply anything in `plugin/patches/`.
- `lune run install` — same as setup minus the codegen step. Use after editing `wally.toml` or patches.
- `lune run dev` — codegen + build + `rojo serve` for live sync into Studio.
- `lune run build` — production build. Produces `Discover.rbxm` at the repo root via `rojo build plugin/default.project.json`.
- `lune run ci` — static analysis: Selene, StyLua check, and luau-lsp type check. Run this before pushing.
- `lune run patch` — two-phase workflow for creating/updating a git-format patch against a Wally package under `plugin/patches/`. First invocation snapshots clean state, second invocation diffs your edits.
- `lune run help` — lists all commands.

Lint config: `selene.toml` (excludes `plugin/Packages/**` and `plugin/generated/**`). Format config: `stylua.toml` (tabs, 120 cols, sorted requires enabled — keep `local` requires alphabetized).

## Architecture

### Source layout

`plugin/src/` is organized into **feature folders**, not by file type. Top-level folders own their components, hooks, and stores together:

- `App.luau` — root component, composes providers.
- `Wally/` — everything that talks to the Wally registry: `Api.luau` (HTTP client), `SearchStore.luau` (Charm atoms + actions), `useWallyStatus.luau` (hook for the rate-limit wait message).
- `Installer/` — `Installer.luau` (downloads + writes to the DataModel), `InstalledPackages.luau` (discovers what's installed by walking the DataModel), `InstalledStore.luau` (Charm atoms mirroring it), and the `zzlib/` unzip dependency.
- `Settings/` — settings React context (`init.luau`) and the package-name formatting helpers it owns.
- `Navigation/` — stack-based router context (`init.luau`).
- `Common/` — truly cross-cutting bits used by multiple features: shared UI components (`PackageCard`, `Pill`, `SectionHeader`, `LinkRow`), the `useAtom` Charm/React bridge, layout helpers (`React.luau` — `createUniqueKey`, `createNextOrder`), and `PackageTypes`.
- `Pages/<Name>/init.luau` — one folder per page. Page-local components sit alongside `init.luau` (e.g. `Pages/Manage/InstalledRow.luau`, `Pages/Package/DependencyGroup.luau`, `Pages/Settings/OverrideRow.luau`). The convention is: **if more than one page uses it, it goes in `Common/`; otherwise it stays inside the page folder.**

`App.luau` composes providers in this order:

```
SettingsProvider          (React context, persisted via plugin:GetSetting)
  └── NavigationProvider  (React context, simple stack-based router)
        └── PageRouter    (renders the current Pages/<Name> based on nav.screen.name)
```

Note: there is both a top-level `Settings/` (the context) and a `Pages/Settings/` (the page). They live in different parents so the require paths (`Discover.Src.Settings` vs `Discover.Src.Pages.Settings`) are unambiguous — don't try to consolidate them.

### State management — Charm atoms, not Redux/context

Global state lives in feature-folder stores as Charm atoms (`littensy/charm`):

- `Wally/SearchStore.luau` — atoms for search text, results, isLoading, hasSearched, error, plus `Search.run(text)` / `Search.clear()` actions. Updates are wrapped in `Charm.batch` so subscribers see one notification per logical change. A module-local `searchVersion` cancels stale in-flight requests.
- `Installer/InstalledStore.luau` — `list` and `map` atoms mirroring installed packages (scanned from the DataModel via `Installer/InstalledPackages`). Call `InstalledState.refresh()` after any install/uninstall — there is no automatic invalidation. Seeded on first require.

Components subscribe via `Common/useAtom.luau`, a small `useState + useEffect + Charm.subscribe` bridge. **Important rules:**

- Each `useAtom(atom)` call only re-renders the calling component when *that* atom changes — this is the whole point of using Charm here. Don't batch unrelated state into one atom.
- Never mutate atom values in place (especially tables). Always pass a new value, otherwise the `~=` change check skips the notification.
- Settings is still a React context (`plugin/src/Settings.luau`) — it's intentionally not on Charm because it isn't a perf bottleneck and the persistence layer is tied to React lifecycle. Don't migrate it speculatively.

### Why this matters: rendering perf

The plugin window stays open for long periods while the user types into the search box. Two patterns guard against re-render storms — preserve them when editing:

1. **`PackageCard` is wrapped in `React.memo`** and takes only primitives + stable callback refs (`onSelect(scope, name)`, `onInstall(scope, name, version)`). The parent provides a single `useCallback` per handler — never inline closures per card, or memo bails.
2. **The search input value lives in local `useState` inside `Home`**, not in `SearchState.text`. The atom is only written on commit (Enter / focus lost). Typing therefore doesn't notify any other subscribers.

### Foundation gotcha: children don't pass through

Foundation components (`TextInput`, `Dropdown.Root`, etc.) **do not forward children**. If you need to attach a `UIFlexItem` or similar to one of them inside a flex row, wrap it in a plain `Frame` and put the `UIFlexItem` on the wrapper. This bug has bitten the search bar and the version dropdown row both — there are wrapper Frames in `Pages/Home` and `Pages/Package` for exactly this reason. Don't "simplify" them away.

### Wally API & rate limiting

`Wally/Api.luau` is the only place that talks to `api.wally.run`. It enforces a shared 1.05s minimum interval between requests (per Wally's policy), serializes via a `nextSlotClock` timestamp, honors `Retry-After` on 429, and exposes a subscribe-able `Status` for the "Waiting Ns…" UI message (consumed by `Wally/useWallyStatus.luau`). Cache TTL is 300s.

`WallyApi.search` returns `description` and `versions[]` per package, so the search results page reads those directly — **do not** fan out to `WallyApi.metadata` for every result (that was the original implementation and made 80-result searches take >80 seconds at 1/sec). The Package detail page is the only place that should call `metadata`.

Roblox `HttpService:RequestAsync` does not allow setting `User-Agent` headers, so requests are identifiable to Wally only as "Roblox Studio". Don't try to add a UA — it'll error.

### Installer & install layout

`Installer/Installer.luau` downloads a Wally package zip, unpacks (via `Installer/zzlib`), creates the alias `ModuleScript` in the appropriate Packages folder (`shared` → `ReplicatedStorage.Packages`, `server` → `ServerStorage.ServerPackages`), and writes deps under `_Index/scope_name@version/`. `Installer/InstalledPackages.luau` discovers what's installed by parsing `require(...)` paths in the alias `ModuleScript.Source` strings — there is no metadata file, the DataModel itself is the source of truth.

After any install/uninstall the caller must `InstalledState.refresh()` so the Charm atom updates.

### Patches

`plugin/patches/` contains git-format patches applied during `lune run install`. If a Wally package needs source-level fixes, use `lune run patch` to author them rather than editing files in `plugin/Packages/` directly (those are gitignored).
