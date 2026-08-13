# Discover

Discover is a Roblox Studio plugin for browsing and installing Luau packages from the [Wally](https://wally.run) and [pesde](https://pesde.dev) registries. It resolves the dependency graph, downloads the archives, and writes the tree into the place you have open.

You can think of Discover as the Studio-native answer to the Rokit/Rojo/Wally CLI toolchain. Same registries, none of the setup.

## What makes Discover special?

Getting one package into a place used to be four tools deep. People install Discover because it isn't. Here's a brief list of the things we can never compromise on.

### 1. No toolchain, no exceptions

Discover is pure Luau running inside Studio. No CLI, no Rokit, no Rojo, no filesystem. Everything ships inside the `.rbxm`: the TOML parser, the semver resolver, the gzip and tar readers. If a feature needs an external tool at runtime, it is not a feature we can ship.

### 2. It writes to somebody's real place

Every install mutates a DataModel that somebody is actively working in. That is the whole product, and it is also the whole risk. Writes go through a `ChangeHistoryService` recording so they are undoable, failures cancel the recording rather than leaving a half-applied tree, and one installer operation runs at a time behind the busy lock in `Installer/runWithBusyLock`. Nothing about this is optional.

### 3. Two registries, one product

Wally and pesde have different APIs, different archive formats, different dependency graphs, and different naming rules. Users don't care, and shouldn't have to. Registry-shaped work needs a decision per registry, even when the decision is "not supported here".

### 4. Studio-native, not Studio-adjacent

The UI is built on Roblox's Foundation design system, so it inherits Studio's light and dark themes and its widget chrome. It has to be readable docked at 306px and comfortable expanded, and it shares the toolbar with peer plugins through SharedToolbar. A plugin that looks pasted in is a plugin people uninstall.

## A note from morgann1

I like ambitious ideas, simple systems, and software that feels obvious. Do not preserve complexity just because it already exists. Do not introduce machinery because it looks architecturally impressive. Understand the real constraint, then fight for the smallest model that makes the correct behavior unsurprising.

Channel both "measure twice, cut once" and "yagni". Fight scope creep. Try to honor the dev's intent in both a minimal and realistic fashion.

The rest of this document is meant to help you navigate the codebase and make changes effectively. Think of these instructions less as "hard rules", more as "good defaults". The developer's preferences should be able to override anything here.

Of note: testing Discover means running it against a real place with real packages in it, usually the contributor's own. Be careful about what you install, uninstall, or bulk-update while iterating.

## A small glossary

We need to be on the same page with terminology. When communicating, use this language:

- **you** means the agent reading this file and changing Discover.
- **we, us, maintainer** means morgann1 and the people building Discover. These are who you are talking to now.
- **user** means the person using Discover to develop games on Roblox.
- **registry** means Wally or pesde: the index Discover searches and downloads from.
- **package** means one scope/name/version in a registry.
- **root** means a package the user asked for directly, as opposed to one pulled in as a dependency.
- **realm** means where a package lands: `shared` in `ReplicatedStorage.Packages`, `server` in `ServerStorage.ServerPackages`. The `dev` realm is rejected on purpose.
- **alias** means the name of the ModuleScript a root gets in `Packages`, after naming-convention and display-name rules are applied. The real content lives under `Packages/_Index`.
- **lockfile** means the `WallyLock` or `PesdeLock` ModuleScript in `ServerStorage`, the record of what is currently resolved in this place.
- **resolve, apply** means the two halves of an install: working out the version graph, then writing it into the DataModel.
- **screen** means one entry in the navigation stack, rendered into the dock widget.

## The three ways to hurt yourself

1. **Assigning `.Source` directly.** Roblox caps `ModuleScript.Source` at 200,000 characters, and a package with one file over that limit takes the entire install down with it. Route every source write through `Core.setScriptSource`, which goes through `ScriptEditorService:UpdateSourceAsync` and has no such limit.
2. **Mutating the place outside a recording.** All DataModel writes belong inside `TryBeginRecording`/`FinishRecording`, and a failure must `Cancel`, not `Commit`. See `Installer/applyRootsAsync`. A half-applied tree the user cannot undo is worse than an install that simply failed.
3. **Editing generated or vendored trees.** `plugin/generated/`, `plugin/Packages/`, and `plugin/DevPackages/` are gitignored and rebuilt by `lute run codegen` and `lute run install`. Anything you write there disappears on the next build. To change a dependency's code, add a patch under `plugin/patches/` with `lute run patch`.

## Hit every surface

The most common defect in this repo is a change that works on the path you tested and is missing everywhere else. Before calling work done, walk this list and say which entries applied:

- **Registries.** Wally and pesde each have their own package, and they never call each other. Fixing the Wally path is not fixing the feature, and reaching across from one into the other is not the fix either. If both need the same thing, it belongs in `packages/core/`.
- **Realms.** `shared` and `server` resolve to different folders, different lockfile entries, and different alias collision sets.
- **Screens.** Home, Package, Manage, Updates, Settings, Display Names, Registries, Changelog. Behavior reachable from the package page is usually also reachable from Manage and Updates.
- **Sidebar modes.** Expanded, Compact, and Auto, which flips on widget width. Every screen has to survive the 306px minimum.
- **Themes.** Foundation gives you light and dark for free, and only if you use its tokens. Never hardcode a color.
- **Settings.** Behavior a user might want off belongs in `SettingsStore`: a default, a GreenTea validator, and a row on the Settings screen. A corrupt saved value must fall back to the default, not crash the plugin.
- **Reverse states.** If you added a way in, add the way out and the way to see it. Install needs uninstall. A one-way door is a bug.
- **Docs.** `docs/process/` is written for us. `README.md` and `CHANGELOG.md` are written for the user, in shipped-product voice, with no repo tooling or source paths.

## Commands

The dev CLI lives in `.lute/`, is written in Luau, and runs under Lute. `cd .lute && lute run help` lists everything.

- `lute setup` generates the Lute typedefs. `lute run setup` does codegen plus package install. Run both once after cloning.
- `lute run install` runs `wally install`, `wally-package-types`, pulls Foundation and friends via `roblox-packages`, then applies patches. If module resolution looks broken, this probably did not run.
- `lute run build` produces `StudioDiscover.rbxm`. `--dev` produces `StudioDiscover-Dev.rbxm` with a separate toolbar, widget, and plugin-settings identity, so it installs alongside the release build without colliding. Use `--dev` when testing.
- `lute run ci` runs Selene, StyLua, a sourcemap refresh, and `luau-lsp analyze`. `--fix` formats instead of checking.
- `lute run test` builds `plugin/tests/build/tests.rbxl` and drives Jest through run-in-roblox.

## Verifying

- `lute run ci` and `lute run test` both pass before a task is done. Not one of them.
- Logic you touch under `plugin/src/` gets a Jest spec in `plugin/tests/`, and you run it.
- run-in-roblox needs a native Roblox Studio install and does not work under WSL. The test command detects WSL and stops after the build. Build there if you like, then run the tests from a native Windows terminal, or open the built place in Studio and run `runTests.server.luau` from the command bar.
- The only real proof of an install path is an install. Ask before running one against a place that matters.

## Pull requests

- Never open a PR unless we explicitly ask you to.
- Conventional commit titles, plain language: `fix(installer): large modules no longer crash the install`.
- Body: the problem in a sentence or two, then how you fixed it. End with the model and harness that did the work.
- Rebase onto latest main before opening. Stale branches conflict and burn a review round.
- Anything a user would notice gets a `CHANGELOG.md` entry under `[Unreleased]`.
- UI changes need before/after screenshots, docked and expanded, light and dark.
- One concern per PR. If the description says "also", split it.

## Bumping the version

The version is duplicated in several places and they all move together, in one commit:

1. `plugin/wally.toml` — `[package].version`. Codegen reads this one to stamp the build.
2. `plugin/wally.lock` — the `morgann1/studio-discover` entry's `version`.
3. `packages/core/src/version.luau` — the runtime version string.
4. `CHANGELOG.md` — a new `## [X.Y.Z] - YYYY-MM-DD` section above the previous release, `[Unreleased]` entries moved into it, and the compare links at the bottom updated.
5. `README.md` — the `### Version X.Y (Latest)` heading and its ToC anchor. Refresh the highlights if the release changed anything user-visible.

Semver: dependency bumps and small fixes are PATCH, new user-visible features are MINOR, breaking changes are MAJOR. Commit as `chore(release): bump version to X.Y.Z`. Do not tag and do not push — we run the release workflow by hand.

## How it works

Search and metadata go through a per-registry HTTP client that is rate limited, honors `Retry-After` on a 429, and caches responses for five minutes. Installing resolves the requested roots against the lockfile in `ServerStorage`, downloads each archive, unzips or untars it in memory, and applies the whole tree into the place inside a single ChangeHistory recording. Roots get an alias ModuleScript in `Packages` pointing at the real content under `Packages/_Index`. UI state is Charm atoms read through ReactCharm; navigation is a screen stack in one atom.

## Where code lives

The repo is a source-only monorepo. `packages/` holds the parts that are really Luau ports of standalone tools, and `plugin/` holds everything coupled to Studio, React, and Charm. Packages are mounted into the build by Rojo, one entry per package in `plugin/default.project.json` and `plugin/test.project.json`; there are no per-package manifests and nothing is published. Adding a package means a mount in both project files, and a `packages/<name>/tests` mount under `Tests` if it has specs. `ANALYZE_PATHS` in `.lute/commands/ci.luau` already covers all of `packages`.

Three rules hold the shape together. A package requires its siblings through the mount name, never through `Source`, and never requires anything under `plugin/src`. The two registry packages never require each other. Third-party code still comes from the one vendored tree at `StudioDiscover.Packages`, since there is a single `wally.toml`; both registry packages take `zzlib` that way.

- `packages/core/` — what both registries and the plugin share: the logger, `setScriptSource`, the TOML reader, the HTTP cache and rate limiter, the archive-to-Instance tree builder, and the shared type vocabulary in `types.luau`. Mounted as `StudioDiscover.Core`.
- `packages/semver/` — parsing and comparison, plus a constraint engine per registry in `wally.luau` and `pesde.luau`. Mounted as `StudioDiscover.Semver`.
- `packages/package-types/` — a Luau port of the wally-package-types CLI. `parseExportedTypes.luau` is the pure half and is where the tests point; `init.luau` returns `processLink`, which rewrites one link module in place. Mounted as `StudioDiscover.PackageTypes`.
- `packages/wally-registry/` — Wally's engine: `Api/` for search, metadata and download; then resolve, apply, lockfile, snapshot, and the naming rules around `_Index`. Mounted as `StudioDiscover.WallyRegistry`.
- `packages/pesde-registry/` — the same surface for pesde, including the tar reader and the normalization from pesde's metadata into `Core.types.PackageMetadata`. Mounted as `StudioDiscover.PesdeRegistry`.
- `plugin/bin/Main.plugin.luau` — the entry point. Everything hangs off `Plugin/setupPlugin`.
- `plugin/src/Api/` — the React hooks over registry search and metadata. The requests themselves live in the registry packages.
- `plugin/src/Installer/` — orchestration only: the ChangeHistory recording, the busy lock, install/update/uninstall, the Charm atoms and the `use*` hooks. The resolve and apply engines live in the registry packages. Most of the risk in this repo lives here.
- `plugin/src/Screens/` — one folder per screen, `init.luau` plus its local pieces.
- `plugin/src/Common/` — shells and hooks shared across screens.
- `plugin/src/Navigation/`, `SettingsStore/`, `SearchStore/` — Charm-backed state, one file per operation.
- `plugin/src/Util/` — one function per file, file named for the function. Anything a package would also want belongs in `packages/core/` instead.
- `plugin/src/Plugin/` — Studio-facing glue: the plugin handle, widget mounting, settings persistence.
- `plugin/Packages/`, `plugin/DevPackages/`, `plugin/generated/` — generated, gitignored, never edited by hand.
- `docs/ui/` — vendored Foundation component reference. Read it before inventing a component that already exists.

## Taste

- Extract before you add. Check whether the logic already exists or can be generalized out of what does. Duplicate logic across files is the smell we care about most, and the fix is refactoring the shared module, not copying it.
- Narrow modules, grouped in folders. `Util/parseSemver.luau`, not a catch-all `Helpers`. Use sibling files to separate responsibilities, not `do`-blocks or IIFE closures pretending to be modules.
- Module-level mutable state that several free functions read and write is a trap. Two independent units of state means two sibling modules with explicit APIs.
- Control flow should be readable from a function's arguments and return values, not by tracing side effects through helpers.
- `--!strict` everywhere. Inferred types over annotations. `any` is the enemy.
- Comments describe how a thing is used, and move when the code moves. Mostly for functions, not a running annotation of every line.
- Users are waiting on a network round trip and a tree write. Report real progress, never a lying spinner. `reduceMotion` is a real setting; honor it.
- If a rule here fights the task in front of you, say so loudly and get sign-off before breaking it.

## Additional tips

- When writing React-Luau code, refer to the pattern guide at `docs/process/react-patterns.md`.
- Don't verify with browsers or computer use unless the user explicitly agrees or requests it.
