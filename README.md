<div align="center">

# 📦 Studio Discover

**A lightweight Roblox Studio plugin for browsing and installing Wally packages — directly from Studio.**

</div>

## Why?

Wally is the standard package manager for Roblox, but installing packages requires the command line, Rojo, and a local sync workflow. Studio Discover lets you search, browse, and install Wally packages entirely within Roblox Studio — no external tools needed.

## Install

### 📥 From Release

1. Download `Discover.rbxm` from the [latest release](https://github.com/morgann1/studio-discover/releases/latest).
2. In Roblox Studio, drag the file into your Plugins folder, or right-click the file and select **Open with Roblox Studio**.
3. The **Discover** button will appear in your toolbar.

### 🔧 From Source

Requires [Rokit](https://github.com/rojo-rbx/rokit).

```sh
git clone https://github.com/morgann1/studio-discover.git
cd studio-discover
rokit install
wally install
rojo sourcemap -o sourcemap.json
wally-package-types --sourcemap sourcemap.json Packages/
rojo build -o Discover.rbxm
```

Then drag `Discover.rbxm` into your Plugins folder in Roblox Studio.
