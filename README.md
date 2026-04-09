<div align="center">

# 📦 Discover

**A lightweight Roblox Studio plugin for browsing and installing Wally packages, right inside Studio.**

</div>

<div align="center">

<img src="/media/search.png" width="250" /> <img src="/media/manager.png" width="250" /> <img src="/media/settings.png" width="250" />

</div>

## Why?

[Wally](https://wally.run) is the go-to package manager for Roblox, but it's a CLI tool that lives outside of Studio. If you're a developer who works purely in Roblox Studio, that means setting up Rokit, Rojo, and a whole external toolchain just to pull in a package. Not everyone wants to make that switch.

[studio-wally](https://github.com/fewkz/studio-wally) exists, but it hasn't been updated in a few years, doesn't support the `server` realm, and depends on the experimental Rojo headless API.

Discover is a pure-Luau alternative. It talks directly to the Wally registry over HTTP, handles both `shared` and `server` realms, generates package types, and writes everything into the DataModel. No external tools required. It aims to replicate what `wally install` and `wally-package-types` do, entirely from inside Studio.

## Install

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
lune run install
lune run build
```

Then follow the same steps as above: drag `Discover.rbxm` into Studio and save it as a local plugin.

> `lune run install` handles the Wally packages, pulls Foundation from the pinned Roblox version, and applies anything under `plugin/patches/`.

## Permissions

The first time you use the plugin, Studio will ask for a couple of permissions:

- **HTTP requests**, so it can talk to the [Wally registry](https://wally.run) and fetch package contents.
- **Script injection**, so it can create the Wally alias `ModuleScript`s and drop package code into `ReplicatedStorage.Packages` or `ServerStorage.ServerPackages`.

Click **Allow** on both and you're set.
