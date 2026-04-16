# Coding Style

## Luau Guidelines and Patterns

Adapted from [Kampfkarren's Luau Guidelines](https://github.com/Kampfkarren/kampfkarren-luau-guidelines/blob/main/README.md). Full source is the canonical reference — this is a working summary.

For React-specific patterns and idioms, see [react-patterns.md](react-patterns.md).

### Philosophy

- **Strict typing everywhere.** Use `--!strict` (or `languageMode: "strict"` in `.luaurc`) for new code. Never add `--!nonstrict` or `--!nocheck` to new scripts.
- **Catch bugs statically.** Prefer typed parameters over runtime `assert(typeof(x) == "...")` guards. A runtime check that a static type would prevent is a worse API.
- **Code should be simple.** Avoid clever code. Small functions with obvious intent beat terse tricks.
- **Prefer immutability.** Mutation makes code less predictable, especially under yields. Critical for React.
- **Build for tools.** Lean on StyLua, selene, and Luau LSP — structure code so they can help.
- **DX over perf.** Only pick uglier code when you can *measure* a real performance hit; keep the ugly blast radius small.

### General code

- **Early return/continue** when the function logically cannot proceed. Don't early return when later code is logically independent.
- **Implementations can be messy if consumers stay clean** (e.g. wrapping `table.move` behind a readable `slice`).
- **In modules, assign to a named variable and return it** — easier to grep, easier to read. Exception: stories and spec files.
- **One file per library function**, not giant `TableUtil` catch-alls. Better testing, fewer cycles, auto-require picks them up.
- **Comments describe now or the future, never yesterday.** No historical comments, no changelogs in source, no commented-out code. Git is the history.
- **Suffix yielding functions with `Async`.** Surprise yields break React and confuse callers.
- **Shallow copy, never deep copy.** With immutability you only need to clone the path you're changing.

### Luau specifics

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

### Roblox

- **`GetService` everything** at the top in alphabetical order. No `game.ServiceName`, no `workspace` global, no mid-file `GetService`.
- **Prefer `UDim2.fromOffset` / `UDim2.fromScale`** over `UDim2.new` when one axis is zero.
- **Nest scripts inside scripts for implementation details** (`Toolbar/init.luau` + `Toolbar/ToolbarButton.luau`).
- **Use absolute paths** (from a service or `FindFirstAncestor`). Avoid `script.Parent` outside implementation details and never chain parents. Exception: stories and tests, which live next to their target and should use `script.Parent`.