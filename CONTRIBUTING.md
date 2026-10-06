# Contributing to Studio Discover

Bug fixes and small improvements can go straight to a pull request. For anything larger, open an issue first so we can agree on the approach before you write it.

## Set up

You need [Rokit](https://github.com/rojo-rbx/rokit). To run the tests, you also need Roblox Studio installed natively on Windows or macOS.

```sh
rokit install
lute scripts/install.luau
```

`install` pulls the Wally packages and Foundation, applies the patches in `plugin/patches/`, and generates `plugin/generated/`. Run it again whenever module resolution looks broken.

## Try a change in Studio

```sh
lute scripts/build.luau --dev
```

This writes `StudioDiscover-Dev.rbxm`. Copy it into your plugins folder, which the Plugins Folder button on Studio's Plugins tab opens. The dev build has its own toolbar button, widget, and saved settings, so it runs alongside the Creator Store release.

Every install writes into the place you have open. Test in a scratch place, never in a game you care about.

## Check your work

```sh
lute scripts/lint.luau     # Selene and StyLua. --fix formats instead of checking.
lute scripts/analyze.luau  # Type check with luau-lsp.
lute scripts/test.luau     # Jest specs, run inside Studio.
```

All three must pass before a pull request is ready. CI runs lint and analyze but cannot run the tests, so run those yourself. The test script needs a native Studio install and does not work under WSL.

Logic you change gets a spec: `plugin/tests/` for the plugin, `packages/<name>/tests/` for a package.

## Ground rules

- Never assign `ModuleScript.Source` directly. Roblox caps it at 200,000 characters, so write through `Core.setScriptSourceAsync` instead.
- Write to the place only inside a `ChangeHistoryService` recording, and cancel the recording if anything fails. `Installer/applyRootsAsync` shows the pattern.
- Don't edit `plugin/Packages/`, `plugin/DevPackages/`, or `plugin/generated/`. The install script rebuilds them. To change a dependency's code, add a patch with `lute scripts/patch.luau <package-path>`.
- Wally and pesde each have their own package, and neither requires the other. A change to registry behavior needs a decision for both. Code they share belongs in `packages/core/`.
- Take colors from Foundation's tokens, never hardcode them. Check UI changes docked at the 306px minimum and expanded, in light and dark themes.

[AGENTS.md](AGENTS.md) covers the architecture and conventions in full. It is written for coding agents, but it is also the most complete guide to the codebase.

## Pull requests

- Title the pull request as a conventional commit in plain language, such as `fix(installer): large modules no longer crash the install`. Release notes are built from these titles, so write them for users.
- Open the description with the problem in a sentence or two, then explain how you fixed it. If an AI tool made the change, name the model and tool at the end.
- Keep one concern per pull request. If the description says "also", split it.
- Include before and after screenshots for UI changes: docked and expanded, light and dark.
- Rebase onto the latest `main` before opening.
- Leave the version alone. Maintainers bump it at release.

## License

By contributing, you agree that your contributions are licensed under the [MIT license](LICENSE).
