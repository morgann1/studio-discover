# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Studio Discover is a Roblox Studio plugin (Luau + React) that lets users browse, install, and manage Wally packages without leaving Studio. The plugin talks directly to the Wally registry HTTP API and writes installed packages into `ReplicatedStorage.Packages` / `ServerStorage.ServerPackages` as alias `ModuleScript`s.

## Best Practices for Clean Code 

1. Use descriptive and obvious names.
    - Don't use abbreviations, use full English words. `player` is better than `plr`.
    - Name things as directly as possible. `wasCalled` is better than `hasBeenCalled`. `notify` is better than `doNotification`.
    - Name booleans as if they are yes or no questions. `isFirstRun` is better than `firstRun`.
    - Name functions using verb forms: `increment` is better than `plusOne`. `unzip` is better than `filesFromZip`.
    - Name event handlers to express when they run. `onClick` is better than `click`.
    - Put statements and expressions in positive form.
        - `isFlying` instead of `isNotFlying`. `late` intead of `notOnTime`.
        - Lead with positive conditionals. Avoid `if not something then ... else ... end`.
        - If we only care about the inverse of a variable, turn it into a positive name. `missingValue` instead of `not hasValue`.
2. Function signatures should be obvious and straightforward at the call site.
    - Avoid boolean arguments that change behavior. Boolean parameters are a [code smell](https://medium.com/@amlcurran/clean-code-the-curse-of-a-boolean-parameter-c237a830b7a3).
    - Avoid `nil` arguments in function calls. Use an optional dictionary with options as the last (or only) parameter instead.
3. Write less code.
    - Be concise: less code means fewer places for bugs to hide which means fewer bugs.
    - Make use of well-supported open source libraries when possible. Try to only spend your time on problems that don't already have solutions.
    - Omit needless variables. Don't assign names to values you only use once.
    - Write good abstractions. Don't repeat yourself.
4. Colocate code related by feature rather than type. Keep related code together.
    - This reduces tight coupling of distinct features.
    - Each feature should manage its own state, and explicitly define methods to access and change that state.
5. Keep code reusable and only tackle one job per function.
    - Don't make one function that both loads and calculates data; allow already loaded data to be calculated, etc.
    - Prefer functions with few or no side effects. This increases testability and re-usability and deters unexpected or unplanned behavior. Side effects are inevitable, but keep them explicitly defined and obvious.
6. "If a feature is sometimes dangerous, and there is a better option, then always use the better option." –Douglas Crockford
    - Avoid using features and patterns that consistently lead to mistakes. Humans are fallible, and you *will* make mistakes.
7. Prefer stateful instances (e.g. classes) rather than excessive data structuring. In other words, if something can exist more than once, then it should be a "class".
    - Avoid global state
    - Prefer composition over inheritance: All class hierarchies are eventually wrong for new use cases. Ask "has a", "uses a", or "can do" instead of "is a".
    - Ensure that anything that is created can also be cleaned up, especially event listeners and state that is associated with objects (instances/classes) that may not exist forever. Be tidy.
    - Prefer getter and setter functions when providing public read and write access to privately managed state. You can't tell the future, and someday you might need to do some processing rather than setting a simple property.
8. Prefer generic solutions which can be applied to many problems rather than specific solutions that can only be applied to one.
    - When a generic solution is not ideal, then write parallel code for parallel concepts. When we repeat similar patterns for similar problems, anybody familiar with the pattern can quickly understand what the code does.
9. Optimize code for reading, not for writing.
    - Comments should answer "why", not "what".
    - Be idiomatic. Follow convention. Use a style guide. When we write code consistently, it makes it easier for others and future you to parse and understand quickly.
    - Code shouldn't be surprising. Overzealous use of meta-programming can lead to future mistakes because of wrong assumptions.
10. Exceptions should be exceptional.
    - Don't indoctrinate exceptions or errors as standard control flow. Not only does this make your code potentially surprising, but it also introduces complexity. Our standard control flow can handle those cases too.
    - Return a success value or state monad. This forces the user to consider the failure case (no accidental uncaught errors!) and makes room for soft-fail situations.
    - Reserve errors for when your program reaches an unrecoverable state. (e.g., unexpected situations or improper function usage)
11. Code should be boring.
13. Untestable code is bad code.

<!-- Variable casing.. camelCase for vars, PascalCase for classes -->

## Toolchain & commands

Toolchain is pinned via `rokit.toml` (run `rokit install` once after cloning). Build / dev workflows are Lune scripts under `.lune/commands/`, invoked from the repo root:

- `lune run setup` — first-time setup: codegen + install Wally packages and package types, then apply anything in `plugin/patches/`.
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
