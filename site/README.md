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

Eleventy writes the static site to `_site/`. The page has one small script, `src/assets/demo.js`,
which plays the product demo. Without it, the demo shows its final frame.

## Publish to GitHub Pages

Set the repository's Pages source to **GitHub Actions**. The Pages workflow builds
and deploys changes to `site/` or the page's shared images when they reach `main`.
You can also run the workflow manually. Pull requests run the build and checks
without deploying.

## Assets

The build copies the plugin icon from `.github/assets/` in the repository.

The demo is the plugin's widget rebuilt in HTML and CSS. Its packages live in
`src/_data/demo.json`, and its markup in `src/_includes/demo.njk`.

The GitHub mark in the header comes from [SVGL](https://svgl.app/library/github_dark.svg).
Its use is subject to [GitHub's brand guidelines](https://brand.github.com/).

`src/assets/wally.png` and `src/assets/pesde.png` are the favicons of
[wally.run](https://wally.run) and [pesde.dev](https://pesde.dev). `src/assets/nevermore.png` is
`Images/NevermoreLogo.png` from [NevermoreEngine](https://github.com/Quenty/NevermoreEngine),
scaled to 48px. These are the same marks the plugin uses.

`src/assets/fonts/BuilderIcons-Subset.woff2` is a subset of Roblox's BuilderIcons font with only
the glyphs the demo draws.

`src/assets/og.png` is the social image. It is `og/og.html` rendered at 1200x630, so it follows
the README's dark screenshot. After that screenshot changes, render it again with Chrome from
`site/`:

```sh
chrome --headless=new --hide-scrollbars --window-size=1200,630 --screenshot=src/assets/og.png og/og.html
```

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
