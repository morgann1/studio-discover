# Luau Style

Adapted from [Kampfkarren's Luau Guidelines](https://github.com/Kampfkarren/kampfkarren-luau-guidelines/blob/main/README.md). Full source is the canonical reference — this is a working summary.

For React-specific patterns and idioms, see [react-patterns.md](react-patterns.md).

## Philosophy

- **Strict typing everywhere.** Use `--!strict` (or `languageMode: "strict"` in `.luaurc`) for new code. Never add `--!nonstrict` or `--!nocheck` to new scripts.
- **Catch bugs statically.** Prefer typed parameters over runtime `assert(typeof(x) == "...")` guards. A runtime check that a static type would prevent is a worse API.
- **Code should be simple.** Avoid clever code. Small functions with obvious intent beat terse tricks.
- **Prefer immutability.** Mutation makes code less predictable, especially under yields. Critical for React.
- **Build for tools.** Lean on StyLua, selene, and Luau LSP — structure code so they can help.
- **DX over perf.** Only pick uglier code when you can *measure* a real performance hit; keep the ugly blast radius small.

## General code

- **Early return/continue** when the function logically cannot proceed. Don't early return when later code is logically independent.
- **Implementations can be messy if consumers stay clean** (e.g. wrapping `table.move` behind a readable `slice`).
- **In modules, assign to a named variable and return it** — easier to grep, easier to read. Exception: stories and spec files.
- **One file per library function**, not giant `TableUtil` catch-alls. Better testing, fewer cycles, auto-require picks them up.
- **No comments.** Code is the source of truth. Don't leave `--` line comments, `--[[ ]]` block comments, docstrings, section banners, or commented-out code. If a reader would need a comment to understand something, rename the identifier, extract a helper, or restructure the code until the intent is obvious from reading it. The only permitted `--` prefixes are Luau directives — `--!strict`, `--!native`, `--!optimize`, `--!nolint`. Everything else gets deleted.
- **Suffix yielding functions with `Async`.** Surprise yields break React and confuse callers.
- **Shallow copy, never deep copy.** With immutability you only need to clone the path you're changing.

## Luau specifics

- **Avoid dynamic requires.** `require` must see a static value for types to flow.
- **No truthiness/falsiness** — write `x.Parent ~= nil`, not `if x.Parent`. Exceptions: `if`-expressions and `and`/`or` defaults.
- **Use `and`/`or` for short-circuits and defaults** (`volume or 0.5`). Do **not** use `x and y or z` as a ternary — it breaks when `y` is falsy. Use `if cond then a else b` instead.
- **Don't alias builtins** (`local insert = table.insert`) — it hides what's actually being called.
- **Don't use string/table call syntax** (`call "x"`, `call { x }`). StyLua normalizes these away.
- **Fully type publicly exposed functions.** Internal helpers can rely on inference.
- **Otherwise avoid trivial types** (`local n: number = 5`) — they're noise and block refactors.
- **Avoid `pcall(x.Destroy, x)` shorthand** for methods — wrap in an anonymous function instead.
- **Use `{ [K]: V? }`** when invalid keys may be indexed, so Luau forces nil handling.
- **`nil` ≠ "nothing".** Be explicit: `return nil` when nil is a meaningful value; bare `return` means void. Keep return arity consistent across branches.
- **String-literal unions are the only enum.** `type Color = "red" | "blue" | "green"`. Pair with an `exhaustiveMatch(value: never): never` helper for completeness checks.
- **Use generalized iteration** (`for i, v in t do`) — skip `pairs`/`ipairs`/`next` unless you truly need ipairs semantics.
- **Keep optional arguments clear.** Put `?` or `| nil` on the outside, not buried mid-union.
- **Always give `assert` an error message.** Use `"Luau"` as the message when the assert only exists to narrow types.
- **`assert` error messages must be constant** — assert evaluates them eagerly. For formatted errors, use `if cond then error(\`...\`) end`.
- **Only assert `typeof` at uncontrolled boundaries** (e.g. RemoteEvents). Type the incoming arg as `unknown` and let narrowing do the work.
- **Avoid metatables.** Prefer C-style free functions over `__index` classes. Skip `__call`, `__add`, etc. entirely. Weak tables (`__mode`) are the rare exception.
- **Sort requires alphabetically, one block, no sections.** Let StyLua's `sort_requires` and Luau LSP auto-require own this.

## Roblox

- **`GetService` everything** at the top in alphabetical order. No `game.ServiceName`, no `workspace` global, no mid-file `GetService`.
- **Prefer `UDim2.fromOffset` / `UDim2.fromScale`** over `UDim2.new` when one axis is zero.
- **Nest scripts inside scripts for implementation details** (`Toolbar/init.luau` + `Toolbar/ToolbarButton.luau`).
- **Use absolute paths** (from a service or `FindFirstAncestor`). Avoid `script.Parent` outside implementation details and never chain parents. Exception: stories and tests, which live next to their target and should use `script.Parent`.

## Code quality

Adapted from [evaera's Code Quality Guidelines](https://gist.github.com/evaera/fee751d4e228dd262fe1174ba142a719). These sit on top of the Luau-specific rules above.

### Naming

- **Full words, not abbreviations** — `player`, not `plr`. Common tight contractions (`pkg`, `req`, `dep`) in small local scope are fine; `plr`, `cnt`, `tbl` are not.
- **Name the outcome, not the ceremony** — `notify`, not `doNotification`; `increment`, not `plusOne`.
- **Booleans are yes/no questions** — `isFirstRun`, `hasPendingChanges`, `isInstallDisabled`. Never `firstRun` or `installIsDisabled`.
- **Event handlers use `on*`** — `onClick`, `onVersionChanged`, `onInstall`. Never `click` / `versionChanged` / `install` for a handler.
- **Positive booleans** — `isFlying`, `isVisible`, `missingValue`. Avoid negative framing (`isNotFlying`, `notVisible`, `notHasValue`) — it forces readers to parse a double negative at every call site.
- **Lead with the positive conditional** — `if isOnline then ... else ... end` reads cleaner than `if not isOffline then ...`.

### Function signatures

- **No boolean flags that swap behavior.** If `fn(x, false)` and `fn(x, true)` do meaningfully different things, split into two named functions: `fnA(x)` and `fnB(x)`. A `kind: "a" | "b"` tag is the acceptable middle ground when you genuinely want one function.
- **No `nil` positional arguments.** `fn(x, nil, nil, true)` is a bug farm. If a function takes optional args, take a `{ }` options record: `fn(x, { retry = true })`.

### Single responsibility

- **Separate data loading from calculation.** A function that fetches AND decides what to do with the fetched data is doing two things. Fetch in one place, pass the data to a calculator. Easier to test, easier to reuse.
- **Side effects are explicit.** A function that reads or mutates state outside its arguments should be named in a way that makes that obvious (`saveFoo`, `loadFoo`, `applyBar`). Pure functions get plain verbs (`parseFoo`, `formatBar`).

### Exception handling

- **Return `(value, error)` tuples for fallible async work**, not exceptions. Luau's `error()` is for truly unrecoverable conditions (programmer mistakes, invariant violations), not for "the server returned 404."
- **If a caller can do something about a failure, it's a return value. If it can't, it's an error.**

### Stateful code

- **Avoid module-level mutable state unless it's a single cohesive unit** with a clear getter/setter API (`SettingsStore`, `SearchStore`, `Installer.installerAtom`). If a module has two or more independent bits of state that callers mutate independently, split them into sibling modules.
- **Resources that can be held (signals, tasks, connections) need cleanup.** Every `:Connect` needs a matching `:Disconnect`. Every `task.spawn` that isn't fire-and-forget needs a way to cancel.

### Boring code

- **Straightforward beats clever.** A ten-line if-chain that a new reader understands in 10 seconds is better than a three-line metatable trick that takes 5 minutes.
- **Follow the conventions already in the codebase** even when you'd personally write it differently. Consistency has a real maintenance value.