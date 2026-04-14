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

- `lune run setup` — first-time setup: codegen + install Wally packages and package types.
- `lune run install` — same as setup minus the codegen step. Use after editing `wally.toml` or patches.
- `lune run dev` — codegen + build + `rojo serve` for live sync into Studio.
- `lune run build` — production build. Produces `Discover.rbxm` at the repo root via `rojo build plugin/default.project.json`.
- `lune run ci` — static analysis: Selene, StyLua check, and luau-lsp type check. Run this before pushing.
- `lune run patch` — two-phase workflow for creating/updating a git-format patch against a Wally package under `plugin/patches/`. First invocation snapshots clean state, second invocation diffs your edits.
- `lune run help` — lists all commands.

Lint config: `selene.toml` (excludes `plugin/Packages/**` and `plugin/generated/**`). Format config: `stylua.toml` (tabs, 120 cols, sorted requires enabled — keep `local` requires alphabetized).

## Architecture

### Source layout

`plugin/src/` groups code by **what job it does**, not by file type:

- `Wally/` — HTTP client for the Wally registry plus the search state and status hook it exposes. Shared by the UI and the installer. *(currently stubs)*
- `Install/` — `wally install` equivalent. Downloads a package zip, unpacks, and writes the alias `ModuleScript` + `_Index/` tree into `ReplicatedStorage.Packages` (shared) or `ServerStorage.ServerPackages` (server). Also owns the `InstalledPackages` walker and the `InstalledStore` Charm atoms that mirror it. *(currently stubs)*
- `PackageTypes/` — `wally-package-types` equivalent. Rewrites alias `ModuleScript.Source` to re-export the underlying package's types so they surface through the alias. *(currently a stub)*
- `UI/` — everything React:
  - `App.luau` — root component. Subscribes to `Navigation.activeScreen`, resolves the named page, renders it inside a `StudioComponents.Background`, and keeps outgoing screens mounted until their exit animation completes.
  - `Navigation.luau` — Charm-backed stack router. Exposes `stack`, `activeScreen`, and `push`/`pop`/`replace`/`reset`. No provider — the module is the source of truth.
  - `Settings.luau` — settings store (persistence via `plugin:SetSetting` / `GetSetting`). *(currently a stub)*
  - `Common/` — cross-cutting components and hooks: `Page` (transition wrapper around react-otter), `StubPage`, `useAtom` (Charm→React bridge). Only things multiple pages share live here.
  - `Pages/<Name>.luau` — one file per screen. If a page grows enough to need private sub-components, promote it to a folder (`Pages/<Name>/init.luau` + siblings); keep cross-page shared pieces in `Common/`.
  - `Util/` — small, side-effect-free helpers: `createNextOrder`, `createUniqueKey`.

### State management — Charm atoms, not Redux/context

Global state is held in Charm atoms (`littensy/charm`) inside the module that owns it — e.g. the search store lives in `Wally/`, the installed-packages store in `Install/`, navigation in `UI/Navigation.luau`. There is no root provider; atoms are module-scoped and imported where needed.

Components subscribe via `UI/Common/useAtom.luau`, a small `useState + useEffect + Charm.subscribe` bridge. **Rules:**

- Each `useAtom(atom)` call only re-renders the calling component when *that* atom changes — this is the whole point of Charm here. Don't batch unrelated state into one atom.
- Never mutate atom values in place (especially tables). Always pass a new value, otherwise the `~=` change check skips the notification.
- Wrap multi-write updates in `Charm.batch` so subscribers see one notification per logical change.

### React conventions

Hoist React hooks and `createElement` to local variables at the top of the file, right after the requires, and use the locals at call sites. This keeps call sites scannable and matches the `local e = React.createElement` pattern that's already everywhere.

```lua
local React = require(Packages.React)

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local useCallback = React.useCallback
```

Only hoist the hooks the file actually uses — don't pull in every hook "just in case".

### Rendering perf: don't let typing in search storm re-renders

The plugin window stays open for long periods while the user types. When the search UI is wired in, preserve these two patterns:

1. **Memoize list rows.** Wrap per-result cards in `React.memo` and pass only primitives + stable callback refs. The parent provides one `useCallback` per handler — never inline closures per card, or memo bails.
2. **Keep the search input value in local `useState`**, not in a global atom. Commit to the atom only on Enter / focus loss. Typing should not notify other subscribers.

### UI library: StudioComponents

The UI is built on `sircfenner/studiocomponents`, which gives components Studio's native chrome (button shapes, input fields, dropdowns, theme colors) via `StudioTheme`. Use SC components at face value — don't try to re-skin them to look like Foundation or anything else. Plain `Frame`s and `UIListLayout` are fine for containers; reach for SC's `Background` for the root and `Label` for any theme-aware text.
