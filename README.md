<div align="center">

# 📦 Studio Discover

**A lightweight Roblox Studio plugin for browsing and installing Wally packages, right inside Studio.**

</div>

## Why?

Wally is the go-to package manager for Roblox, but using it normally means jumping between a terminal, Rojo, and a sync workflow just to try a package. Studio Discover skips all of that. You can search, browse, and install Wally packages without ever leaving Studio.

## Install

### 📥 From Release

1. Grab `Discover.rbxm` from the [latest release](https://github.com/morgann1/studio-discover/releases/latest).
2. In Roblox Studio, drag the file into your Plugins folder (or right-click it and pick **Open with Roblox Studio**).
3. A **Discover** button should show up in your toolbar.

### 🔧 From Source

You'll need [Rokit](https://github.com/rojo-rbx/rokit) and [Lune](https://github.com/lune-org/lune).

```sh
git clone https://github.com/morgann1/studio-discover.git
cd studio-discover
rokit install
lune run install
rojo build plugin/default.project.json -o Discover.rbxm
```

Then drag `Discover.rbxm` into your Plugins folder in Studio.

> `lune run install` handles the Wally packages, pulls Foundation from the pinned Roblox version, and applies anything under `plugin/patches/`.

## Permissions

The first time you use the plugin, Studio will ask for a couple of permissions:

- **HTTP requests**, so it can talk to the [Wally registry](https://wally.run) and fetch package contents.
- **Script injection**, so it can create the Wally alias `ModuleScript`s and drop package code into `ReplicatedStorage.Packages` or `ServerStorage.ServerPackages`.

Click **Allow** on both and you're set.
