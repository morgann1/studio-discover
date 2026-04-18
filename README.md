<a name="top"></a>
![Studio Discover](./.github/assets/banner.jpg)
[![Download](https://raw.githubusercontent.com/maneetoo/Roblox-OSS-Badges/main/Badges/Roblox-Styled/Original/link-download.svg)](https://github.com/morgann1/studio-discover/releases/latest/download/Discover.rbxm)
[![GitHub Repository](https://raw.githubusercontent.com/maneetoo/Roblox-OSS-Badges/main/Badges/Community/GitHub/link-github-repository.svg)](https://github.com/morgann1/studio-discover)
[![GitHub Releases](https://raw.githubusercontent.com/maneetoo/Roblox-OSS-Badges/main/Badges/Community/GitHub/link-github-releases.svg)](https://github.com/morgann1/studio-discover/releases/latest)

## 🚀 About

[Wally](https://wally.run/) is the most popular package manager for Roblox, but it's a CLI tool that lives outside of Studio. If you're a game creator who works purely in Roblox Studio, that means setting up Rokit, Rojo, and a whole external toolchain just to pull in a package. Not everyone wants to make that switch.

[studio-wally](https://github.com/fewkz/studio-wally) exists, but it hasn't been updated in over a year, [doesn't support the server realm](https://github.com/fewkz/studio-wally/issues/4), and depends on the [experimental Rojo headless API](https://github.com/rojo-rbx/rojo/pull/639).

Studio Discover is a pure-Luau alternative. It talks directly to the Wally registry over HTTP, handles both `shared` and `server` realms, re-exports package types through link modules, and writes everything into the DataModel. No external tools required. It aims to replicate what `wally install` and `wally-package-types` do, entirely from inside Roblox Studio.

## ✨ What's New

### Version 3.5 (Latest)

🚨 **Breaking Changes**
- **"Backend URL" setting removed**: The short-lived Cloudflare Worker proxy added earlier in this cycle was rolled back before release, so any existing Backend URL configuration is ignored.

✏️ **Improvements**
- **Plugin renamed to "Studio Discover"**: Both the plugin title and repo have moved off the single-word "Discover" name to avoid collisions and make the product's scope clear.
- **Direct Wally API calls**: The plugin now talks to `api.wally.run` directly with an `X-Real-User-Agent` header — UpliftGames confirmed direct Studio requests are fine, so the intermediate proxy is gone.
- **Wording refresh**: Plugin UI and README rewritten to speak to game creators rather than pure developers.

🔒 **Security**
- **Anonymous-session guard**: The plugin refuses to mount when a Studio `userId` isn't available, so it never makes network calls on behalf of an unidentified user.

> See 📋 [`CHANGELOG.md`](./CHANGELOG.md) for full details.

## 📝 How to Build

### Prerequisites

1. [Rokit](https://github.com/rojo-rbx/rokit)
2. [Lune](https://github.com/lune-org/lune)

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
lune run install

# Build the plugin
lune run build
```

Then drag the generated `Discover.rbxm` into Roblox Studio, right-click the **Discover** folder in the Explorer, and pick **Save / Export > Save as Local Plugin**. A **Discover** button will appear in your toolbar.

> `lune run install` fetches the Wally packages, pulls Foundation from the pinned Roblox version, and applies anything under `plugin/patches/`.

> If you plan to fork this or contribute, also run `lune run setup` — luau-lsp won't resolve things out of the box without it.