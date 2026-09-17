# Studio Discover website

## Preview the page

Run these commands in `site/` with Node.js 24:

```sh
npm ci
npm run dev
```

Open the local URL printed by Eleventy.

## Build and check the page

```sh
npm run format:check
npm run lint
npm run build -- --pathprefix=/studio-discover/
```

Eleventy writes the static site to `_site/`. The page has no browser JavaScript.

## Publish to GitHub Pages

Set the repository's Pages source to **GitHub Actions**. The Pages workflow builds
and deploys changes to `site/` or the page's shared images when they reach `main`.
You can also run the workflow manually. Pull requests run the build and checks
without deploying.

## Assets

The build copies the icon and screenshot from `.github/assets/` in the repository.

The white GitHub mark in `src/assets/github.svg` comes from
[SVGL](https://svgl.app/library/github_dark.svg). Its use is subject to
[GitHub's brand guidelines](https://brand.github.com/).

Builder Sans Regular and SemiBold are self-hosted in `src/assets/fonts/`. The files
come from Roblox's Foundation CDN:

- <https://cdn.foundation.roblox.com/current/fonts/builder-sans/BuilderSans-Regular.woff2>
- <https://cdn.foundation.roblox.com/current/fonts/builder-sans/BuilderSans-SemiBold.woff2>

The [Builder font license](https://create.roblox.com/docs/resources/builder-font-license)
permits digital promotions incorporating Roblox UGC outside Roblox. This page
promotes the Studio Discover plugin and includes a screenshot of it. The font's
copyright and license are included in `src/assets/fonts/LICENSE.txt` and copied
to the published site. The fonts are subject to that license, not the repository's
MIT license.
