# Changelog

All notable changes to Studio Discover are documented in this file.

The format is loosely based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### ✨ New
- Dock widget title flags pending updates with a " · N update(s)" suffix.
- Settings screen has a "Reset to Defaults" row that restores every setting (display name overrides included) after a confirm.
- About page now shows the build commit alongside the version (embedded at build time).

### ✏️ Improvements
- About page simplified: no more external URL links or "Built with" section — just identity + version + commit + author + license.

## [3.7.0] - 2026-04-22

### ✨ New
- Browse and install packages from the [pesde](https://pesde.dev) registry alongside Wally.
- Release workflow publishes to the [Creator Store listing](https://create.roblox.com/store/asset/91442200339606), so Studio auto-updates the plugin from there.
- `lute run build --dev` produces a parallel `StudioDiscover-Dev.rbxm` with its own toolbar slot, widget, and plugin settings namespace for side-by-side testing against the release version.
- Plugin version is embedded in the dock widget title (matching Rojo's convention).

### ✏️ Improvements
- Plugin registers with the shared `22:43 Plugin Suite` toolbar via SharedToolbar 0.2.1.
- Installer no longer creates empty `Packages`/`DevPackages`/`ServerPackages` folders it doesn't need during snapshot.
- Dev tooling migrated from Lune to Lute (contributor-only change).

### 🛠 Fixes
- Script injection denials now surface a clear "retry so Studio prompts you to allow it" message instead of the raw Roblox error.
- Navigating to a package's dependency from the Package screen preserves the source registry (previously defaulted back to Wally).

### 🗑 Removed
- GitHub-release self-update check and the Check for Updates setting — Creator Store handles plugin updates now.

## [3.6.0] - 2026-04-19

### ✨ New
- Installed page lists every top-level package with a Remove action that also drops orphaned dependencies.
- Updates page lists packages with a newer release, with per-row and Update-All actions.
- Home page now shows a curated Featured list instead of a blank placeholder.
- Sidebar badges the Updates item with the pending count.
- Display Names setting overrides the auto-formatted alias per package name (scope-agnostic).
- About page shows version, license, links, and a release-check row when Check for Updates is on.
- Install button and Remove/Update buttons morph into a progress bar while the operation runs.

### ✏️ Improvements
- Installer serializes concurrent install/uninstall/update operations so they can't race on `_Index` or the lockfile.
- Installer preserves prior top-level roots when adding a new one; re-installs replace by `(realm, scope, name)` and disambiguate alias collisions with a numeric suffix.
- Install button reflects on-disk install state across plugin reloads, not just the transient atom.
- HTTP requests include the Studio user id in `X-Real-User-Agent`; plugin skips init when no user is signed in.

### 🛠 Fixes
- Installer now preserves a package's main module when reusing an on-disk package.
- Root-package apply failures cancel the ChangeHistory waypoint so a botched install doesn't land on the undo stack.
- Wally `/package-contents` requests now send the `Wally-Version` header required by the registry.
- Uninstall and update surface errors inline and reset the row action instead of sticking in a progress state.
- Long search-result titles and descriptions wrap instead of overflowing the dock widget.
- About page URLs render without the `FontFace` property error on older Foundation builds.

## [3.5.0] - 2026-04-17

### 🚨 Breaking Changes
- Removed the "Backend URL" setting. The short-lived Cloudflare Worker proxy added earlier in this cycle was rolled back before release, so the plugin now talks to `api.wally.run` directly.

### ✏️ Improvements
- Renamed plugin from "Discover" to "Studio Discover".
- Plugin calls `api.wally.run` directly with an `X-Real-User-Agent` header (UpliftGames confirmed direct Studio requests are fine).
- Wording refresh across the plugin UI and README to speak to game creators.

### 🔒 Security
- Plugin refuses to mount when a Studio `userId` isn't available, so it never makes network calls on behalf of an unidentified user.

## [2.6.0] - 2026-04-15

### 🚀 Features
- "Reduce motion" setting that skips page transitions.
- Dependency buttons on the package page now preselect the pinned version on navigate.

### ✏️ Improvements
- Installer re-resolves the full root set on every install (matching the Wally CLI model).
- React root is now mounted lazily the first time the dock widget opens.

### 🛠 Fixes
- Stack router returns the rebuilt rendered list instead of leaking the outer `next` global.
- Wally package author name corrected.

## [2.5.0] - 2026-04-12

### 🚨 Breaking Changes
- Installer blocks attempts to install dev-realm packages. Existing workflows that relied on dev-realm installs will need to be updated.

### 🚀 Features
- "Verbose logging" setting for install debugging.
- Home page shows popular packages on the empty state.
- Toolbar icon swaps between light and dark based on the Studio theme.
- camelCase and snake_case naming-convention options, with per-package overrides moved to a dedicated page.

### ✏️ Improvements
- Package page reorganised around a collapsible `Section` component.
- Update checker only runs while the dock widget is visible.

### 🛠 Fixes
- Installer handles anchored globs, `./`-prefixed source paths, and file-based sources.
- Installer resolves the file filter correctly for packages using an exclude-all-then-include pattern.
- Plugin skips initialisation when the game is running.

## [2.4.2] - 2026-04-10

### 🛠 Fixes
- Installer handles file-based source paths and cross-realm garbage collection.
- Package-type generation matches `wally-package-types` default handling for generics.

## [2.4.0] - 2026-04-10

Initial release.

### 🚀 Features
- Browse, search, install, and manage Wally packages from inside Roblox Studio via a dock widget.
- Installer rewritten to match `wally install` behavior (version resolution, realm promotion, lockfile in `ServerStorage.WallyLock`, `default.project.json` parsing, `wally.toml` include/exclude filtering).
- Update checker with a dismissable banner when a new GitHub release is available.
- Cross-slide page transitions powered by Otter springs.
- Foundation theme synced with the current Studio theme.
- Manage page with uninstall-confirmation dialog and a "skip confirmation" option.
- Settings page with row-based layout.
- Opt-in "skip test files on install" setting.
- Realm resolution from metadata for search-initiated installs.

### 🛠 Fixes
- Toolbar button icon asset ID.
- Metadata-fetch `useEffect` now cleans up on unmount.
- Partial-install error message wording.

[Unreleased]: https://github.com/morgann1/studio-discover/compare/v3.7.0...HEAD
[3.7.0]: https://github.com/morgann1/studio-discover/compare/v3.6.0...v3.7.0
[3.6.0]: https://github.com/morgann1/studio-discover/compare/v3.5.0...v3.6.0
[3.5.0]: https://github.com/morgann1/studio-discover/compare/v2.6.0...v3.5.0
[2.6.0]: https://github.com/morgann1/studio-discover/compare/v2.5.0...v2.6.0
[2.5.0]: https://github.com/morgann1/studio-discover/compare/v2.4.2...v2.5.0
[2.4.2]: https://github.com/morgann1/studio-discover/compare/v2.4.0...v2.4.2
[2.4.0]: https://github.com/morgann1/studio-discover/releases/tag/v2.4.0
