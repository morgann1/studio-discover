<a name="top"></a>
![Studio Discover](./.github/assets/banner.jpg)
[![Download](https://raw.githubusercontent.com/maneetoo/Roblox-OSS-Badges/main/Badges/Roblox-Styled/Original/link-download.svg)](https://github.com/morgann1/studio-discover/releases/latest/download/Discover.rbxm)
[![GitHub Repository](https://raw.githubusercontent.com/maneetoo/Roblox-OSS-Badges/main/Badges/Community/GitHub/link-github-repository.svg)](https://github.com/morgann1/studio-discover)
[![GitHub Releases](https://raw.githubusercontent.com/maneetoo/Roblox-OSS-Badges/main/Badges/Community/GitHub/link-github-releases.svg)](https://github.com/morgann1/studio-discover/releases/latest)


## 🚀 About

[Wally](https://wally.run/) is the most popular package manager for Roblox, but it's a CLI tool that lives outside of Studio. If you're a game creator who works purely in Roblox Studio, that means setting up Rokit, Rojo, and a whole external toolchain just to pull in a package. Not everyone wants to make that switch.

[studio-wally](https://github.com/fewkz/studio-wally) exists, but it hasn't been updated in over a year, [doesn't support the server realm](https://github.com/fewkz/studio-wally/issues/4), and depends on the [experimental Rojo headless API](https://github.com/rojo-rbx/rojo/pull/639).

Studio Discover is a pure-Luau alternative. It talks directly to the Wally registry over HTTP, handles both `shared` and `server` realms, re-exports package types through link modules, and writes everything into the DataModel. No external tools required. It aims to replicate what `wally install` and `wally-package-types` do, entirely from inside Roblox Studio.