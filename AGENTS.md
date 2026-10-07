# Discover

Discover is a Roblox Studio plugin for browsing and installing Luau packages from the [Wally](https://wally.run) and [pesde](https://pesde.dev) registries, and Nevermore packages from npm. It resolves the dependency graph, downloads the archives, and writes the tree into the place you have open.

You can think of Discover as the Studio-native answer to the Rokit/Rojo/Wally CLI toolchain. Same registries, none of the setup.

## What makes Discover special?

Getting one package into a place used to be four tools deep. People install Discover because it isn't. Here's a brief list of the things we can never compromise on.

### 1. No toolchain, no exceptions

Discover is pure Luau running inside Studio. No CLI, no Rokit, no Rojo, no filesystem. Everything ships inside the `.rbxm`: the TOML parser, the semver resolver, the gzip and tar readers. If a feature needs an external tool at runtime, it is not a feature we can ship.

### 2. It writes to somebody's real place

Every install mutates a DataModel that somebody is actively working in. That is the whole product, and it is also the whole risk. Writes go through a `ChangeHistoryService` recording so they are undoable, failures cancel the recording rather than leaving a half-applied tree, and one installer operation runs at a time behind the busy lock in `Installer/runWithBusyLock`. Nothing about this is optional.

### 3. Three registries, one product

Wally, pesde, and Nevermore have different APIs, different archive formats, different dependency graphs, and different naming rules. Nevermore isn't a registry of its own: its packages live on npm, and they install into the npm-style `node_modules` tree the Nevermore loader expects. Users don't care, and shouldn't have to. Registry-shaped work needs a decision per registry, even when the decision is "not supported here".

### 4. Studio-native, not Studio-adjacent

The UI is built on Roblox's Foundation design system, so it inherits Studio's light and dark themes and its widget chrome. It has to be readable docked at 306px and comfortable expanded. A plugin that looks pasted in is a plugin people uninstall.

## A note from morgann1

I like ambitious ideas, simple systems, and software that feels obvious. Do not preserve complexity just because it already exists. Do not introduce machinery because it looks architecturally impressive. Understand the real constraint, then fight for the smallest model that makes the correct behavior unsurprising.

Channel both "measure twice, cut once" and "yagni". Fight scope creep. Try to honor the dev's intent in both a minimal and realistic fashion.

The rest of this document is meant to help you navigate the codebase and make changes effectively. Think of these instructions less as "hard rules", more as "good defaults". The developer's preferences should be able to override anything here.

Of note: testing Discover means running it against a real place with real packages in it, usually the contributor's own. Be careful about what you install, uninstall, or bulk-update while iterating.

## A small glossary

We need to be on the same page with terminology. When communicating, use this language:

- **you** means the agent reading this file and changing Discover.
- **we, us, and maintainers** mean morgann1 and the people building Discover. These are who you are talking to now.
- **user** means the person using Discover to develop games on Roblox.
- **registry** means Wally, pesde, or Nevermore: the index Discover searches and downloads from. For Nevermore that index is npm.
- **package** means one scope/name/version in a registry.
- **root** means a package the user asked for directly, as opposed to one pulled in as a dependency.
- **realm** means where a package lands: `shared` in `ReplicatedStorage.Packages`, `server` in `ServerStorage.ServerPackages`. The `dev` realm is rejected on purpose. Nevermore has no realms: every root reads as `shared` and lands in `ServerScriptService.Nevermore.node_modules`. The Nevermore loader decides at runtime what replicates to the client.
- **alias** means the name of the ModuleScript a root gets in `Packages`, after naming-convention and display-name rules are applied. The real content lives under `Packages/_Index`. A Nevermore root has no link module, so its alias is the npm folder name, like `characterutils`. The UI shows the module name people require instead, like `CharacterUtils`, through `Util/rootDisplayName`.
- **lockfile** means the `WallyLock`, `PesdeLock`, or `NevermoreLock` ModuleScript in `ServerStorage`, the record of what is currently resolved in this place.
- **resolve, apply** means the two halves of an install: working out the version graph, then writing it into the DataModel.
- **screen** means one entry in the navigation stack, rendered into the dock widget.

## The three ways to hurt yourself

1. **Assigning `.Source` directly.** Roblox caps `ModuleScript.Source` at 200,000 characters, and a package with one file over that limit takes the entire install down with it. Route every source write through `Core.setScriptSourceAsync`, which goes through `ScriptEditorService:UpdateSourceAsync` and has no such limit.
2. **Mutating the place outside a recording.** All DataModel writes belong inside `TryBeginRecording`/`FinishRecording`, and a failure must `Cancel`, not `Commit`. See `Installer/applyRootsAsync`. A half-applied tree the user cannot undo is worse than an install that simply failed.
3. **Editing generated or vendored trees.** `plugin/generated/`, `plugin/Packages/`, and `plugin/DevPackages/` are gitignored and rebuilt by `scripts/codegen.luau` and `scripts/install.luau`. Anything you write there disappears on the next build. To change a dependency's code, add a patch under `plugin/patches/` with `scripts/patch.luau`.

## Hit every surface

The most common defect in this repo is a change that works on the path you tested and is missing everywhere else. Before calling work done, walk this list and say which entries applied:

- **Registries.** Wally, pesde, and Nevermore each have their own package, and they never call each other. Fixing the Wally path is not fixing the feature, and reaching across from one into another is not the fix either. If two of them need the same thing, it belongs in `packages/core/`.
- **Realms.** `shared` and `server` resolve to different folders, different lockfile entries, and different alias collision sets. Nevermore has only the one folder, so realm-shaped UI needs a Nevermore answer too.
- **Screens.** Installed, Updates, each source, Search, Package, Settings, Display names. Behavior reachable from the package page is usually also reachable from Installed and Updates.
- **Layouts.** Above Foundation's Small breakpoint the sidebar shows unless the user hides it; at Small and below the widget is docked and the header carries the location menu. Columns follow the widget's width, and the header follows whether the sidebar shows. Every screen has to survive the 306px minimum.
- **Themes.** Foundation gives you light and dark for free, and only if you use its tokens. Never hardcode a color.
- **Settings.** Behavior a user might want off belongs in `SettingsStore`: a default, a GreenTea validator, and a row on the Settings screen. A corrupt saved value must fall back to the default, not crash the plugin.
- **Reverse states.** If you added a way in, add the way out and the way to see it. Install needs uninstall. A one-way door is a bug.
- **Docs.** `README.md` is written for the user, in shipped-product voice, with no repo tooling or source paths.

## Commands

The dev scripts live in `scripts/`, are written in Luau, and run under Lute from the repo root: `lute scripts/<name>.luau`. One file per command at the top level. Helpers shared between them live in `scripts/lib/`, one function per file, and code that runs inside Roblox rather than Lute lives in `scripts/tasks/`. Paths and version pins they share live in `project.luau` at the root. Scripts require through the `@scripts` and `@root` aliases in `.luaurc`. There is no help command, so this list is the index. A script reads its arguments with `lib/parseArgs`, which skips `process.args[1]` because that is the script path.

- `install` gets a clone ready: it generates the Lute typedefs, runs `wally install` and `wally-package-types`, pulls Foundation and friends via `roblox-packages`, applies patches, and writes `plugin/generated/`. Run it once after cloning. If module resolution looks broken, this probably did not run.
- `build` produces `StudioDiscover.rbxm`. `--dev` produces `StudioDiscover-Dev.rbxm` with a separate toolbar, widget, and plugin-settings identity, so it installs alongside the release build without colliding. Use `--dev` when testing.
- `lint` runs Selene and a StyLua check. `--fix` formats instead of checking.
- `analyze` runs `luau-lsp analyze` twice, both with the new solver: the scripts against the standard platform, and the plugin, the packages, and `scripts/tasks/` against Roblox through the plugin's sourcemap. It downloads the Roblox global types pinned in `project.luau` and checks their hash.
- `test` builds `plugin/tests/build/tests.rbxl` and runs `scripts/tasks/run-tests.luau` in it through run-in-roblox. `--build-only` stops after the build.
- `patch <package-path>` snapshots a vendored package on the first run and writes the diff to `plugin/patches/` on the second.
- `codegen` regenerates `plugin/generated/` and the sourcemap. `upload-plugin <path>` publishes to the Creator Store by running `scripts/tasks/upload-plugin.luau` as an Open Cloud Luau Execution task, and the release workflow is what normally calls it.
- `nevermore-names` regenerates `packages/nevermore-registry/src/knownNames.luau`, the module name each Nevermore package goes by, from the NevermoreEngine source tree and an npm search. Rerun it when Quenty publishes new packages. When it names a package wrong, fix its `OVERRIDES`, not the output. The header comment in `scripts/nevermore-names.luau` explains the rules.
- `sync` shallow-clones the reference repos into the gitignored `.repos/`. Ones we depend on at a version are pinned to the tag matching `rokit.toml`; the rest follow their branch. `--dry-run` prints the plan, `--repo <id>` limits it to one, `--latest` ignores the pins. Declared in `scripts/lib/referenceRepos.luau`.

## Verifying

- **`lint`, `analyze`, and `test` all pass before a task is done.** Not some of them.
- Logic you touch under `plugin/src/` gets a Jest spec in `plugin/tests/`, and you run it.
- run-in-roblox needs a native Roblox Studio install and does not work under WSL. The test script detects WSL and stops after the build. Build there if you like, then run the tests from a native Windows terminal, or open the built place in Studio and paste `scripts/tasks/run-tests.luau` into the command bar.
- The only real proof of an install path is an install. Ask before running one against a place that matters.

## Pull requests

- Never open a PR unless we explicitly ask you to.
- Conventional commit titles, plain language: `fix(installer): large modules no longer crash the install`.
- Body: the problem in a sentence or two, then how you fixed it. End with the model and harness that did the work.
- **Rebase onto latest main before opening.** Stale branches conflict and burn a review round.
- Release notes are generated from the commits between tags, so the PR title is what ships to users. Write it that way.
- UI changes need before/after screenshots, docked and expanded, light and dark.
- One concern per PR. If the description says "also", split it.

## Bumping the version

The version is duplicated in several places and they all move together, in one commit:

1. `plugin/wally.toml` - `[package].version`. Codegen reads this one to stamp the build.
2. `plugin/wally.lock` - the `morgann1/studio-discover` entry's `version`.
3. `packages/core/src/version.luau` - the runtime version string.

Semver: dependency bumps and small fixes are PATCH, new user-visible features are MINOR, breaking changes are MAJOR. Commit as `chore(release): bump version to X.Y.Z`. Do not tag and do not push. We run the release workflow by hand.

## How it works

Search and metadata go through a per-registry HTTP client that is rate limited, honors `Retry-After` on a 429, and caches responses for five minutes. Installing resolves the requested roots against the lockfile in `ServerStorage`, downloads each archive, unzips or untars it in memory, and applies the whole tree into the place inside a single ChangeHistory recording. Wally and pesde roots get an alias ModuleScript in `Packages` pointing at the real content under `Packages/_Index`. Nevermore packages go into `node_modules` folders laid out the way npm would, with no link modules. UI state is Charm atoms read through `Common/useAtom`; navigation is a back and forward history of screens in one atom.

## Where code lives

The repo is a source-only monorepo. `packages/` holds the parts that are really Luau ports of standalone tools, and `plugin/` holds everything coupled to Studio, React, and Charm. Packages are mounted into the build by Rojo, one entry per package in `plugin/default.project.json` and `plugin/test.project.json`; there are no per-package manifests and nothing is published. Adding a package means a mount under `Libraries` in both project files, and a `packages/<name>/tests` mount under `Tests.Libraries` if it has specs. `scripts/lint.luau` and `scripts/analyze.luau` already cover all of `packages`.

Three rules hold the shape together. A package requires its siblings through `StudioDiscover.Libraries`, never through `StudioDiscover.Source`, and never requires anything under `plugin/src`. The registry packages never require each other. Third-party code still comes from the one vendored tree at `StudioDiscover.Packages`, since there is a single `wally.toml`. Core wraps `zzlib` from that tree as `Core.zzlib`, and every registry package takes it from there.

- `packages/core/` - what the registries and the plugin share: the logger, `setScriptSourceAsync`, the TOML reader, the tar reader, the HTTP client with its cache and rate limiter, the lockfile subtree walk in `collectLockedSubtree`, and the shared type vocabulary in `types.luau`. `buildTree` and `writePendingSourcesAsync` turn an archive into Instances, including `.rbxm` and `.rbxmx` models through `SerializationService`. `readProjectSourcePath` and `relativeToSource` pick out the part of an archive a package's `default.project.json` installs. Mounted as `StudioDiscover.Libraries.Core`.
- `packages/semver/` - parsing and comparison, plus a constraint engine per registry in `wally.luau`, `pesde.luau`, and `npm.luau`. Mounted as `StudioDiscover.Libraries.Semver`.
- `packages/package-types/` - a Luau port of the wally-package-types CLI. `parseExportedTypes.luau` reads exported types out of source for Wally and pesde. `forwardTypes.luau` turns them into the `export type` lines a Wally link needs, by the CLI's rules, and `processLinkAsync.luau` rewrites one Wally link module in place. Nevermore has no link modules, so it forwards no types. Mounted as `StudioDiscover.Libraries.PackageTypes`.
- `packages/wally-registry/` - Wally's engine: `Api/` for search, metadata and download; then resolve, apply, lockfile, snapshot, and the naming rules around `_Index`. Mounted as `StudioDiscover.Libraries.WallyRegistry`.
- `packages/pesde-registry/` - the same surface for pesde, including the normalization from pesde's metadata into `Core.types.PackageMetadata`, and its own `forwardTypes.luau`, since pesde forwards types by different rules than wally-package-types. Mounted as `StudioDiscover.Libraries.PesdeRegistry`.
- `packages/nevermore-registry/` - the same surface for Nevermore. It reads npm directly, resolves npm ranges through `Semver.npm`, and lays packages out the way npm would in `layoutPackages.luau`. On the first install, `setUpGameAsync.luau` creates the game folder and the `ServerMain` and `ClientMain` scripts that start the loader. `nevermore-names` generates its `knownNames.luau`. Mounted as `StudioDiscover.Libraries.NevermoreRegistry`.
- `plugin/bin/Main.plugin.luau` - the entry point. Everything hangs off `Plugin/setupPlugin`.
- `plugin/src/Api/` - the React hooks over registry search and metadata. The requests themselves live in the registry packages.
- `plugin/src/Installer/` - orchestration only: the ChangeHistory recording, the busy lock, install/update/uninstall, the Charm atoms and the `use*` hooks. The resolve and apply engines live in the registry packages. Most of the risk in this repo lives here.
- `plugin/src/Screens/` - one folder per screen, `init.luau` plus its local pieces.
- `plugin/src/Common/` - shells and hooks shared across screens.
- `plugin/src/Navigation/`, `SettingsStore/`, `SearchStore/`, `SidebarStore/` - Charm-backed state, one file per operation.
- `plugin/src/Util/` - one function per file, file named for the function. Anything a package would also want belongs in `packages/core/` instead.
- `plugin/src/Plugin/` - Studio-facing glue: the plugin handle, widget mounting, settings persistence.
- `plugin/Packages/`, `plugin/DevPackages/`, `plugin/generated/` - generated, gitignored, never edited by hand. The plugin build leaves the vendored specs, stories, and `__tests__` folders out through `globIgnorePaths` in `default.project.json`. Some of them call `getfenv` or `InsertService:LoadAsset`, which Creator Store moderation flags.
- `.repos/` - local read-only references, gitignored and absent until you run `lute scripts/sync.luau`. Prefer their patterns over invented ones. Never edit or import from them. Sync again when bumping the matching dependency.

## Taste

- Extract before you add. Check whether the logic already exists or can be generalized out of what does. Duplicate logic across files is the smell we care about most, and the fix is refactoring the shared module, not copying it.
- Narrow modules, grouped in folders. `Util/parseSemver.luau`, not a catch-all `Helpers`. Use sibling files to separate responsibilities, not `do`-blocks or IIFE closures pretending to be modules.
- Module-level mutable state that several free functions read and write is a trap. Two independent units of state means two sibling modules with explicit APIs.
- Control flow should be readable from a function's arguments and return values, not by tracing side effects through helpers.
- `--!strict` everywhere. Inferred types over annotations. `any` is the enemy.
- Type component props inline with `read` fields. The new solver infers `createElement`'s props invariantly, so a `number` passed to a mutable `number?` prop fails. `plugin/patches/` makes React's own element types read-only for the same reason.
- Comments describe how a thing is used, and move when the code moves. Mostly for functions, not a running annotation of every line.
- Users are waiting on a network round trip and a tree write. Report real progress, never a lying spinner. `reduceMotion` is a real setting; honor it.
- If a rule here fights the task in front of you, say so loudly and get sign-off before breaking it.

## Additional tips

- Don't verify with browsers or computer use unless the user explicitly agrees or requests it.
