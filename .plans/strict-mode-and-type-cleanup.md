# Strict mode and type cleanup for plugin/src/

Bring every file in `plugin/src/` in line with `luau-style.md` and `react-patterns.md`. Audit surfaced three systematic violations.

## 1. Enable strict mode project-wide

Add `"languageMode": "strict"` to `plugin/.luaurc` (create the file if it doesn't exist — root `.luaurc` only has `aliases`). This is the `or configure .luaurc with { "languageMode": "strict" }` alternative both style guides call out.

Scope: every `.luau` file under `plugin/src/` is currently in the default mode.

Do **not** add `--!strict` per-file — one config change covers the tree.

Run `lune run ci` after — many violations in sections 2 and 3 will surface as hard type errors.

## 2. Replace `any` with `unknown` / concrete types / `React.ReactNode`

Luau-style: "Type the incoming arg as `unknown` and let narrowing do the work." `any` is a last resort.

| File:line | Current | Target |
|---|---|---|
| `Api/Wally.luau:23` | `{ data: any, time: number }` cache | `{ data: unknown, time: number }` + narrow at read sites |
| `WallyInstall/WallyInstall.luau:52,65` | `compareSemver(a: any, b: any)`, `semverCompatible(a: any, b: any)` | Use `{ major: number, minor: number, patch: number }` (already declared as local type line 44–50) |
| `WallyInstall/WallyInstall.luau:75` | `caretUpperBound(sv: any): any` | Same semver shape |
| `WallyInstall/WallyInstall.luau:159,380` | `data :: any`, `resolved[entry.packageId] :: any` | Narrow instead of cast |
| `App.luau:97,98` | `(widget :: any).Enabled` | Cast to `DockWidgetPluginGui` — the known runtime type |
| `Common/Page.luau:16` | `component: any` | `React.ComponentType<any>` |
| `Common/Page.luau:17` | `pageProps: { [string]: any }?` | Props shape depends on the page being rendered — keep as `{ [string]: unknown }?` |
| `Navigation/init.luau:13,17,19,47,70` | `options: { [string]: any }?` | `{ [string]: unknown }?` |
| `Navigation/init.luau:44` | `props: { children: any }` | `{ children: React.ReactNode }` |
| `Settings/SettingsStore.luau:23,75` | `setSetting: (key: string, value: any)` | `value: unknown` (callers validate at boundary) |
| `Settings/SettingsStore.luau:70` | `children: any` | `React.ReactNode` |
| Dependency-array casts `:: { any }` — ~15 instances across `App.luau`, `Common/Page.luau`, `Common/PackageCard.luau`, `Common/useAtom.luau`, `Home/Home.luau`, `Manage/*`, `Navigation/init.luau`, `Overrides/Overrides.luau`, `Package/*`, `Settings/SettingsView.luau`, `UpdateChecker.luau` | Replace with `:: { unknown }` — matches react-patterns.md's own examples (`useEventConnection`) |
| React children tables `{ [string]: any }` — ~10 instances | `{ [string]: React.ReactNode }` (invalid keys will still type-check via `{ [K]: V? }` rule if needed) |

## 3. Kill truthiness / falsiness checks

Luau-style: "No truthiness/falsiness — write `x.Parent ~= nil`, not `if x.Parent`." Exceptions: `if`-expressions, `and`/`or` defaults, and booleans (so `if not ok then` on a pcall result is fine).

Replace `if x then` / `if not x then` with `if x ~= nil then` / `if x == nil then` everywhere `x` is a nilable non-boolean.

**Systematic — expect 30+ sites.** Known representatives:

- `Api/Wally.luau:89,142,148,157,176,195` — `headers`, `errorMessage`, `body`, `data` (all nilable)
- `Api/useWallyStatus.luau:34` — `tickHandle: thread?`
- `Package/Package.luau:66,99,178,230,238` — `requestedVersion`, `lastSegment`, `source`, `allVersions`
- `Package/DependencyGroup.luau:34,38,72` — `scopeName`, `dependencyScope`
- `Package/useInstaller.luau:54` — `success` (pcall-style, check if bool or nilable)
- `Manage/InstalledRow.luau:45,67` — `onUpdate`, `updateAvailable`
- `Manage/Manage.luau:75,85,242` — `target`, `matchedPackage`, `pendingUninstall`
- `Settings/SettingsStore.luau:43,62,137` — `pluginInstance`, `override`
- `WallyPackageTypes/WallyPackageTypes.luau:16,91,113,126,130,154,157,162,181,206` — most are nilable match captures
- `WallyInstall/WallyInstall.luau:46,90,92,98,106,204,262,286,305,373,385,398,402,449,454,462,470,494,553,573,587,590,658,710,728,764,787,821,830,841,886,945,973,987` — dominant source of violations

**Do not rewrite:** `if not ok then` when `ok` is a `pcall` / `xpcall` boolean. Same for other explicit booleans.

## Execution order

1. Section 1 first (one-line config change). Run `lune run ci`.
2. Section 3 next — most sites are obvious find/replace. Run `lune run ci` after each file.
3. Section 2 last — concrete typing may require propagating types through call sites, so do it on the stable foundation.
4. Final `lune run ci`.

## Done when

- `lune run ci` passes.
- Grep `:\s*any\b|::\s*any\b|\{\s*any\s*\}` against `plugin/src/` returns only intentional cases (e.g., true heterogeneous-value boundaries documented with a comment).
- No `if not? <nilable-nonboolean> then` in `plugin/src/`.
