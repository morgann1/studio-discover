# Pesde installer

Port pesde's package install pipeline to the Studio Discover plugin.

Target version: **pesde v0.7.3** (released, what users actually run). NOT the in-progress `main` refactor in `ref/pesde/`. All citations below reference `git show v0.7.3+registry.0.2.3:…`.

- **Download URL template**: `{API_URL}/v1/packages/{PACKAGE}/{PACKAGE_VERSION}/{PACKAGE_TARGET}/archive` — `source/pesde/mod.rs:429`. Hardcode the default; we can't read the git index config.
- **Headers**: `Accept: application/octet-stream`. Optional `Authorization`. No token support in plugin v1.
- **Body**: gzipped ustar tar. `zzlib.gunzip` + pure-Luau tar reader required.
- **Ignored names**: files `foreman.toml`, `aftman.toml`, `rokit.toml`, `.DS_Store`, `default.project.json`; dirs `.git`. (`source/mod.rs:40,43,46`)
- **Output dir**: ONE folder per project per dep-target — `{dep_target}_packages/`. For Roblox deps that's `roblox_packages/`. No `shared_packages/server_packages/` in v0.7.3. (`manifest/target.rs:70`)
- **Container layout**:
  - pesde-native: `.pesde/{scope}+{name}/{version}/{name}/…` — 3 levels. (`graph.rs:60–62`)
  - wally-proxied: `.pesde/{scope}_{name}@{version}/{name}/…` — 2 levels, `_` separator. (`graph.rs:49–52`)
- **Direct dep alias**: `{roblox_packages}/{alias}.luau` — next to `.pesde/`. (`linking/mod.rs:72`)
- **Transitive dep alias**:
  - pesde v2 (`use_new_structure=true`): inside the dependant's container, `…/conch/roblox_packages/{dep_alias}.luau`.
  - wally (`use_new_structure=false`): parent of the dependant's `{name}` folder, `…/conch_1.2.3/{dep_alias}.luau`.
  - (`graph.rs:34–42`, `linking/mod.rs:207–217`)
- **Alias linker template**: `local module = require({path})\n{types}\nreturn module`. (`linking/generator.rs:95–105`)
- **Require path (Roblox target)** — 3 branches in `linking/generator.rs:132–183`:
  1. Dest outside root container → `manifest.place[Shared|Server]:FindFirstChild(...)` chain.
  2. Dest inside root + wally dep → `script.Parent:FindFirstChild(...)` chain.
  3. Dest inside root + pesde-v2 dep → **require-by-string** (`"./.pesde/…"`). Unreliable in Studio; plugin must substitute an instance-chain require.
- **`[place]` map** (`manifest/mod.rs:94–96`): user-supplied in their `pesde.toml`, defaulting typically to `game.ReplicatedStorage.Packages` (Shared) / `game.ServerStorage.Packages` (Server). Plugin hardcodes these (or reads from plugin settings).
- **Resolver**: queue DFS; three dep kinds; `dev` skipped in transitive. (`resolver.rs:302–304`)
- **Lockfile (v0.7.3)**: `format = 2`; struct has `name, version, target, overrides, workspace, graph`. Graph = `BTreeMap<PackageId, DependencyGraphNode>`. Node has `direct: Option<(alias, specifier_inline_table, type)>`, `dependencies: BTreeMap<alias, (package_id, type)>`, `pkg_ref: PackageRefs`. PackageId Display: `"{scope}/{name}@{version} {target}"` with a literal space. (`lockfile.rs`, `graph.rs`, `source/ids.rs:128–130`)
- **Lockfile interchange**: requires inline-table parsing (for `DependencySpecifiers`) — beyond our current lute-derived TOML module. **Not in scope for v1**; plugin uses an internal ModuleScript-based lockfile like Wally installer does.
- **Wally inside pesde**: deps whose `pkg_ref` is `WallyPackageRef` use `use_new_structure=false`; resolve via Wally registry APIs. Reuse existing `Api/Wally/*` + `Installer/Wally/downloadAndExtractAsync` shape.

## Deliberately out of scope (v1)

- Cross-registry deps where a pesde package depends on a wally package **with a different index** than the plugin's hardcoded one. (We'll handle the common default-index case.)
- Type re-exports in alias modules (needs Luau AST parsing).
- Patches (`patches.rs`). Requires git-diff application.
- Lockfile compatibility with pesde CLI. Ship internal format first.
- Workspace members, overrides, engines, scripts, require-by-string mode, bin exports.
- Lune / Luau targets. Roblox / RobloxServer only.

## Phases

### Phase 1 — utilities (unblocks everything)

- [x] `plugin/src/Installer/Pesde/packageId.luau` — format/parse `"scope/name@version target"` (verified display format).
- [x] `plugin/src/Installer/Pesde/containerName.luau` — escape scope/name for the `.pesde/` subfolder. Native: `scope+name`. Wally-proxied: `scope_name@version`.
- [x] `plugin/src/Installer/Pesde/tarAsync.luau` — pure-Luau ustar reader. Walks the tar stream, yields `{ path, kind, content }`. Dispatches by `typeflag` with trailing-`/` fallback (GNU tar uses space for files in ustar).
- [x] Smoke-test tar reader with a synthetic input and a real pesde archive (conch 0.4.0-rc.6 — 14 entries, pesde.toml recovered with correct content).

### Phase 2 — download + extract

- [ ] `plugin/src/Api/Pesde/downloadAsync.luau` — issues the archive GET, returns raw bytes. Uses rate-limiter. Cache on `{scope}/{name}@{version}/{target}`.
- [ ] `plugin/src/Installer/Pesde/downloadAndExtractAsync.luau` — gunzip (zzlib) → tarAsync → filter ignored names → emit `{ path, content }` entries → buildTree. Reuse `Installer/Wally/buildTree` + `classifyFile` unless they make wally-specific assumptions (verify).
- [ ] Smoke-test against a real pesde package (e.g., `alicesaidhi/conch`).

### Phase 3 — link generation

- [ ] `plugin/src/Installer/Pesde/buildPackageLink.luau` — emits `ModuleScript.Source` for alias linker modules. Four variants to consider: direct-dep-shared, direct-dep-server, transitive-in-same-package, transitive-cross-target. Output = `FindFirstChild`-chain requires, never require-by-string.
- [ ] `plugin/src/Installer/Pesde/getPackagesFolder.luau` — produce `PesdePackages` Folder in ReplicatedStorage (matching Wally installer's convention of root-level folder per realm). Decide: one folder or two (shared/server)? Pick one → document.

### Phase 4 — apply (DataModel mutations)

- [ ] `plugin/src/Installer/Pesde/applyAsync.luau` — mirrors `Wally/applyAsync.luau`, producing the nested `.pesde/{container}/…` layout. Drop orphaned packages. Emit alias linkers at the top of the packages folder (direct) or inside the dependant (transitive).

### Phase 5 — resolve

- [ ] `plugin/src/Installer/Pesde/resolveAsync.luau` — walks pesde metadata via existing `Api/Pesde/getMetadataAsync`. Three dep kinds; dev-in-transitive skipped. Handle wally-proxied deps by dispatching to `Api/Wally/getMetadataAsync` when the metadata indicates wally provenance.
- [ ] Verify `Api/Pesde/getMetadataAsync` preserves enough wally-vs-pesde info in its normalized shape; extend if not.

### Phase 6 — lockfile

- [ ] `plugin/src/Installer/Pesde/lockfile.luau` — internal ModuleScript format (`PesdeLock` in ServerStorage), same pattern as `Wally/lockfile.luau`. Not pesde-CLI-compatible.

### Phase 7 — dispatcher wiring

- [ ] `plugin/src/Installer/installAsync.luau` — take `registry: "wally" | "pesde"` arg; dispatch to the registry-specific resolver + applier.
- [ ] `plugin/src/Installer/applyRootsAsync.luau` — same dispatch.
- [ ] `plugin/src/Installer/uninstallAsync.luau`, `updateAllAsync.luau` — same.
- [ ] `plugin/src/Installer/snapshotRoots.luau` — walk both Wally and Pesde packages folders.

### Phase 8 — UI gate

- [ ] `plugin/src/Screens/PackageScreen/init.luau:267` — flip `isInstallBlocked = selectedRegistry == "pesde"` off.
- [ ] Test end-to-end with `alicesaidhi/conch` and a package that has transitive deps.

## Open questions (resolve as we encounter)

- Are there real pesde packages that require `[place]` values other than the two defaults? (Unlikely, but check top-downloaded list.)
- Does `buildTree` need Luau-vs-other extension handling specific to pesde? (It only cares about `.lua`/`.luau`/`init.*` today; should be fine.)
- Will Studio throw on ModuleScript names containing `+` or `@`? (Need to probe; escape if so.)
