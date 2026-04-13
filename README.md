<div align="center">

# 📦 Discover

**A Roblox Studio plugin for browsing and installing Wally packages.**

</div>

<table align="center">
  <tr>
    <td align="center"><img src="/media/home.png" width="200" /><br /><b>Home</b></td>
    <td align="center"><img src="/media/search.png" width="200" /><br /><b>Search</b></td>
    <td align="center"><img src="/media/manager.png" width="200" /><br /><b>Manager</b></td>
    <td align="center"><img src="/media/settings.png" width="200" /><br /><b>Settings</b></td>
  </tr>
</table>

<div align="center">

<a href="https://github.com/morgann1/studio-discover/actions/workflows/lint.yml"><img src="https://github.com/morgann1/studio-discover/actions/workflows/lint.yml/badge.svg" alt="Lint" /></a>
<a href="https://github.com/morgann1/studio-discover/actions/workflows/release.yml"><img src="https://github.com/morgann1/studio-discover/actions/workflows/release.yml/badge.svg" alt="Release" /></a>

</div>

## 💡 Motivation

[Wally](https://wally.run) is the most popular package manager for Roblox, but it's a CLI tool that lives outside of Studio. If you're a developer who works purely in Roblox Studio, that means setting up Rokit, Rojo, and a whole external toolchain just to pull in a package. Not everyone wants to make that switch.

[studio-wally](https://github.com/fewkz/studio-wally) exists, but it hasn't been updated in a few years, doesn't support the `server` realm, and depends on the experimental Rojo headless API.

Discover is a pure-Luau alternative. It talks directly to the Wally registry over HTTP, handles both `shared` and `server` realms, re-exports package types through link modules, and writes everything into the DataModel. No external tools required. It aims to replicate what `wally install` and `wally-package-types` do, entirely from inside Studio.

## 🔌 Install

### 📥 From Release

1. Grab `Discover.rbxm` from the [latest release](https://github.com/morgann1/studio-discover/releases/latest).
2. Drag the file into Roblox Studio. It'll usually land in Workspace.
3. Right-click the **Discover** folder and pick **Save / Export > Save as Local Plugin**.
4. A **Discover** button should show up in your toolbar.

### 🔧 From Source

You'll need [Rokit](https://github.com/rojo-rbx/rokit) and [Lune](https://github.com/lune-org/lune).

```sh
git clone https://github.com/morgann1/studio-discover.git
cd studio-discover
rokit install
git config core.hooksPath .githooks
lune run install
lune run build
```

Then follow the same steps as above: drag `Discover.rbxm` into Studio and save it as a local plugin.

> `lune run install` handles the Wally packages, pulls Foundation from the pinned Roblox version, and applies anything under `plugin/patches/`.

## 🙏 Credits

The Lune build scripts were originally taken from [grilme99/studio-activity](https://github.com/grilme99/studio-activity) and updated to work cross-platform.
