--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Foundation = require(StudioDiscover.Packages.Foundation)
local React = require(StudioDiscover.Packages.React)

local Content = require(StudioDiscover.Source.Common.Content)
local Screen = require(StudioDiscover.Source.Common.Screen)
local Section = require(StudioDiscover.Source.Common.Section)
local Version = require(StudioDiscover.Source.Util.Version)
local compareSemver = require(StudioDiscover.Source.Util.compareSemver)
local createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)
local parseSemver = require(StudioDiscover.Source.Util.parseSemver)
local useLatestVersion = require(StudioDiscover.Source.Api.useLatestVersion)

local LinkRow = require(script.LinkRow)

local Text = Foundation.Text
local View = Foundation.View

local e = React.createElement

local TAGLINE = "Browse and install Wally packages without leaving Roblox Studio."
local DESCRIPTION = "Studio Discover is a pure-Luau alternative to the Wally CLI. It talks to the Wally "
	.. "registry directly, handles the shared and server realms, re-exports package types through link modules, "
	.. "and writes everything into the DataModel. No external toolchain required."

local function AboutScreen()
	local latest = useLatestVersion()

	local updateLabel: string? = nil
	if latest.version ~= nil then
		local latestSv = parseSemver(latest.version)
		local currentSv = parseSemver(Version)
		if latestSv ~= nil and currentSv ~= nil and compareSemver(latestSv, currentSv) > 0 then
			updateLabel = `v{latest.version} available`
		else
			updateLabel = "Up to date"
		end
	elseif latest.loading then
		updateLabel = "Checking…"
	end

	local nextOrder = createNextOrder()
	local nextHeaderOrder = createNextOrder()
	local nextAboutOrder = createNextOrder()
	local nextLinkOrder = createNextOrder()
	local nextCreditOrder = createNextOrder()

	return e(Screen, { title = "About" }, {
		Body = e(Content, {}, {
			Header = e(View, {
				tag = "size-full-0 auto-y col gap-xsmall",
				LayoutOrder = nextOrder(),
			}, {
				Title = e(Text, {
					tag = "size-full-0 auto-y text-title-large content-emphasis text-align-x-left",
					Text = "Studio Discover",
					LayoutOrder = nextHeaderOrder(),
				}),
				Subtitle = e(Text, {
					tag = "size-full-0 auto-y text-body-small content-muted text-align-x-left",
					Text = `v{Version} · {TAGLINE}`,
					LayoutOrder = nextHeaderOrder(),
				}),
			}),

			Description = e(Text, {
				tag = "size-full-0 auto-y text-body-medium content-default text-align-x-left text-wrap",
				Text = DESCRIPTION,
				LayoutOrder = nextOrder(),
			}),

			About = e(Section, {
				title = "About",
				LayoutOrder = nextOrder(),
			}, {
				Version = e(LinkRow, {
					label = "Version",
					url = Version,
					LayoutOrder = nextAboutOrder(),
				}),
				Update = if updateLabel ~= nil
					then e(LinkRow, {
						label = "Update",
						url = updateLabel,
						LayoutOrder = nextAboutOrder(),
					})
					else nil,
				License = e(LinkRow, {
					label = "License",
					url = "Permissive (see repository)",
					LayoutOrder = nextAboutOrder(),
				}),
				Author = e(LinkRow, {
					label = "Author",
					url = "morgann1",
					LayoutOrder = nextAboutOrder(),
				}),
			}),

			Links = e(Section, {
				title = "Links",
				LayoutOrder = nextOrder(),
			}, {
				Repository = e(LinkRow, {
					label = "Repository",
					url = "https://github.com/morgann1/studio-discover",
					LayoutOrder = nextLinkOrder(),
				}),
				Releases = e(LinkRow, {
					label = "Releases",
					url = "https://github.com/morgann1/studio-discover/releases/latest",
					LayoutOrder = nextLinkOrder(),
				}),
				Changelog = e(LinkRow, {
					label = "Changelog",
					url = "https://github.com/morgann1/studio-discover/blob/main/CHANGELOG.md",
					LayoutOrder = nextLinkOrder(),
				}),
				Issues = e(LinkRow, {
					label = "Report an issue",
					url = "https://github.com/morgann1/studio-discover/issues",
					LayoutOrder = nextLinkOrder(),
				}),
			}),

			BuiltWith = e(Section, {
				title = "Built with",
				LayoutOrder = nextOrder(),
			}, {
				Wally = e(LinkRow, {
					label = "Wally",
					url = "https://wally.run",
					LayoutOrder = nextCreditOrder(),
				}),
				Foundation = e(LinkRow, {
					label = "Foundation",
					url = "https://github.com/Roblox/foundation",
					LayoutOrder = nextCreditOrder(),
				}),
				Charm = e(LinkRow, {
					label = "Charm",
					url = "https://charm.dev",
					LayoutOrder = nextCreditOrder(),
				}),
				React = e(LinkRow, {
					label = "React",
					url = "https://github.com/jsdotlua/react-lua",
					LayoutOrder = nextCreditOrder(),
				}),
			}),
		}),
	})
end

return AboutScreen
