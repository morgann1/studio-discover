![Studio Discover](./.github/assets/banner.jpg)
<a name="top"></a>

[![Luau](./.github/assets/badges/link-luau.svg)](https://luau.org/)
[![Creator Store](./.github/assets/badges/link-creator-store.svg)](https://create.roblox.com/store/asset/91442200339606)
[![GitHub Releases](./.github/assets/badges/link-github-releases.svg)](https://github.com/morgann1/studio-discover/releases/latest)
[![GitHub Repository](./.github/assets/badges/link-github-repository.svg)](https://github.com/morgann1/studio-discover)

[![Changelog](./.github/assets/badges/link-changelog.svg)](./CHANGELOG.md)
[![My Profile](./.github/assets/badges/link-my-profile.svg)](https://www.roblox.com/users/48044582/profile)
[![Contributions Welcome](./.github/assets/badges/link-contributions.svg)](#-feedback-and-contributions)

[![CI](https://github.com/morgann1/studio-discover/actions/workflows/ci.yml/badge.svg)](https://github.com/morgann1/studio-discover/actions/workflows/ci.yml)
[![Release](https://github.com/morgann1/studio-discover/actions/workflows/release.yml/badge.svg)](https://github.com/morgann1/studio-discover/actions/workflows/release.yml)
[![Latest release](https://img.shields.io/github/v/release/morgann1/studio-discover?display_name=tag&label=release)](https://github.com/morgann1/studio-discover/releases/latest)
[![Stars](https://img.shields.io/github/stars/morgann1/studio-discover)](https://github.com/morgann1/studio-discover/stargazers)

## Table of Contents
- [Table of Contents](#table-of-contents)
- [🚀 About](#-about)
- [📸 Screenshots](#-screenshots)
- [✨ What's New](#-whats-new)
  - [Version 3.7 (Latest)](#version-37-latest)
- [📝 How to Build](#-how-to-build)
  - [Prerequisites](#prerequisites)
  - [Build](#build)
  - [Releasing](#releasing)
- [🤝 Feedback and Contributions](#-feedback-and-contributions)
- [🙏 Credits](#-credits)
- [📃 License](#-license)

## 🚀 About

If you want to use a Luau package in Roblox Studio, the usual path is a bit of a trek. You install [Wally](https://wally.run/) or [pesde](https://pesde.dev/), set up Rokit, set up Rojo, wire it into your project, and only then can you actually `require` the thing. Great if you're already deep in that workflow. A lot of hassle if you just want to use a package.

Studio Discover skips the setup. Browse Wally and pesde packages from inside Studio, hit install, and the package shows up in your place — dependencies, types, and all.

## 📸 Screenshots

<details>
<summary>Click to expand</summary>

**Expanded sidebar**

<p align="center">
  <img src="./.github/assets/screenshots/expanded/home.png" width="420" alt="Home" title="Home" />
  <img src="./.github/assets/screenshots/expanded/installed.png" width="420" alt="Installed" title="Installed" />
  <br />
  <img src="./.github/assets/screenshots/expanded/updates.png" width="420" alt="Updates" title="Updates" />
  <img src="./.github/assets/screenshots/expanded/settings.png" width="420" alt="Settings" title="Settings" />
  <br />
  <img src="./.github/assets/screenshots/expanded/about.png" width="420" alt="About" title="About" />
</p>

**Collapsed sidebar**

<p align="center">
  <img src="./.github/assets/screenshots/collapsed/home.png" width="420" alt="Home (collapsed)" title="Home (collapsed)" />
  <img src="./.github/assets/screenshots/collapsed/installed.png" width="420" alt="Installed (collapsed)" title="Installed (collapsed)" />
  <br />
  <img src="./.github/assets/screenshots/collapsed/updates.png" width="420" alt="Updates (collapsed)" title="Updates (collapsed)" />
  <img src="./.github/assets/screenshots/collapsed/settings.png" width="420" alt="Settings (collapsed)" title="Settings (collapsed)" />
  <br />
  <img src="./.github/assets/screenshots/collapsed/about.png" width="420" alt="About (collapsed)" title="About (collapsed)" />
</p>

</details>

## ✨ What's New

### Version 3.7 (Latest)

✨ **New**
- **Creator Store distribution**: releases now auto-publish to the [Creator Store listing](https://create.roblox.com/store/asset/91442200339606), so Studio keeps the plugin up to date for you.
- **pesde registry**: browse and install packages from [pesde](https://pesde.dev) alongside Wally.
- **Dev build variant**: `lute run build --dev` produces `StudioDiscover-Dev.rbxm` with its own toolbar slot, widget, and settings namespace for side-by-side testing against the Creator Store version.
- **Versioned widget title**: the dock widget now includes the plugin version (matching Rojo's convention).

✏️ **Improvements**
- **Shared toolbar slot**: the button registers under the `22:43 Plugin Suite` toolbar via SharedToolbar.
- **Less Explorer noise**: installer no longer creates empty `Packages`/`DevPackages`/`ServerPackages` folders during snapshot.

🛠 **Fixes**
- **Clearer permission errors**: script injection denials explain what happened and tell you to retry so Studio shows the actual permission dialog.
- **Dependency navigation registry**: opening a dependency from the Package screen now keeps the source registry instead of defaulting back to Wally.

🗑 **Removed**
- GitHub-release self-update check and the Check for Updates setting — the Creator Store handles plugin updates now.

> See 📋 [`CHANGELOG.md`](./CHANGELOG.md) for full details.

## 📝 How to Build

### Prerequisites

You'll need [Rokit](https://github.com/rojo-rbx/rokit) installed.

### Build

To build the plugin, follow these steps:

```shell
# Open a terminal (Command Prompt or PowerShell for Windows, Terminal for macOS or Linux)

# Clone the repository
git clone https://github.com/morgann1/studio-discover.git

# Navigate to the project directory
cd studio-discover

# Install the toolchain
rokit install

# Install wally packages, patch in the `Foundation` package.
lute run install

# Build the plugin
lute run build
```

Then drag the generated `StudioDiscover.rbxm` into Roblox Studio, right-click the **Discover** folder in the Explorer, and pick **Save / Export > Save as Local Plugin**. A **Discover** button will appear in your toolbar.

> `lute run install` fetches the Wally packages, pulls Foundation from the pinned Roblox version, and applies anything under `plugin/patches/`.

> If you plan to fork this or contribute, also run `lute run setup`. Without it, luau-lsp won't resolve things out of the box.

> To test changes alongside the creator store version without collisions, run `lute run build --dev`. This produces `StudioDiscover-Dev.rbxm` with its own toolbar slot, widget, and plugin settings namespace.

### Releasing

Pushing a `v*` tag runs `.github/workflows/release.yml`, which builds `StudioDiscover.rbxm` and creates a GitHub release with the notes drawn from `CHANGELOG.md`.

**The Creator Store listing is updated manually**: Open Cloud does not yet support updating Plugin-type assets, so after the GitHub release lands, download the release `.rbxm`, insert it in Studio, right-click the `Discover` folder, and pick **Publish as Plugin → Update Existing**.

## 🤝 Feedback and Contributions

[![Open issues](https://img.shields.io/github/issues/morgann1/studio-discover)](https://github.com/morgann1/studio-discover/issues)
[![Open pull requests](https://img.shields.io/github/issues-pr/morgann1/studio-discover)](https://github.com/morgann1/studio-discover/pulls)

Issues and pull requests are welcome.

- **Bugs and feature requests**: open an issue at [GitHub Issues](https://github.com/morgann1/studio-discover/issues).
- **Pull requests**: before opening one, please file an issue describing the change so we can agree on direction. Run `lute run ci` locally before pushing. It mirrors what CI checks.
- **Scope**: contributions that fit the project's goals (see [About](#-about)) are the easiest to land. Studio Discover is a solo project, so response times vary.

## 🙏 Credits

Studio Discover is built on top of work from a lot of other people. Thank you to:

- [**cxmeel**](https://github.com/cxmeel) — the Luau, Creator Store, GitHub Releases, and GitHub Repository badges are from their [Markdown Buttons gist](https://gist.github.com/cxmeel/b3af232eba0ace022e2fba8b7b286520).
- [**maneetoo**](https://github.com/maneetoo/Roblox-OSS-Badges) — the Changelog and My Profile badges are from their Roblox OSS Badges collection.
- [**Roblox**](https://github.com/Roblox/foundation) — the **Foundation** UI library the plugin is built with, and the Contributions Welcome badge in this README is from Roblox's own assets.
- [**UpliftGames**](https://wally.run) and [**daimond113**](https://pesde.dev) — for the **Wally** and **pesde** registries the plugin queries.
- [**jsdotlua**](https://github.com/jsdotlua/react-lua) — the **React** port for Roblox.
- [**littensy**](https://github.com/littensy/charm) — **Charm** and **ReactCharm** for reactivity.
- [**Corecii**](https://github.com/Corecii/GreenTea) — **GreenTea** for runtime type checking.
- [**evaera**](https://github.com/evaera/roblox-lua-promise) — the **Promise** implementation.
- [**roblox-rbx**](https://github.com/rojo-rbx) — **Rojo** and **Rokit** for project sync and toolchain management.
- The [**Luau**](https://luau.org/) team and the [**Lute**](https://github.com/luau-lang/lute) project — for the language and the standalone runtime that powers the build/CI scripts.
- [**grilme99**](https://github.com/grilme99) — the `.lute` build/CI scripts started as a port of their `.lune` scripts from [studio-activity](https://github.com/grilme99/studio-activity), reworked to be cross-platform and adapted for this project.
- [**flipbook-labs**](https://github.com/flipbook-labs) — the [`roblox-packages`](https://github.com/flipbook-labs/roblox-packages) crate pulls Foundation (Roblox's modern Studio UI components) into the build; without it the plugin would likely be sitting on [StudioComponents](https://github.com/sircfenner/StudioComponents) or a hand-rolled UI instead.

## 📃 License

Studio Discover's own source is intended to be freely redistributable. Read it, fork it, modify it, ship it. There's no `LICENSE` file in the repo yet, but the intent is permissive (MIT or similar).

The one thing to watch out for is [Foundation](https://github.com/Roblox/foundation), Roblox's UI library. The built `StudioDiscover.rbxm` bundles it at build time, and Foundation is not open source, so redistributing the *built artifact* is subject to Roblox's terms for Foundation, not this repo's license. A proper `LICENSE` will be added once Foundation is either swapped out or its redistribution terms are confirmed.

For now: do whatever you want with the source in this repo, but check Foundation's terms before redistributing the build.

[Back to top](#top)