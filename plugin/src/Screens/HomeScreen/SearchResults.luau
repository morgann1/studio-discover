--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Foundation = require(StudioDiscover.Packages.Foundation)
local React = require(StudioDiscover.Packages.React)
local ReactCharm = require(StudioDiscover.Packages.ReactCharm)

local Content = require(StudioDiscover.Source.Common.Content)
local Navigation = require(StudioDiscover.Source.Navigation)
local SettingsStore = require(StudioDiscover.Source.SettingsStore)
local createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)
local formatName = require(StudioDiscover.Source.Util.formatName)
local useSearchPackages = require(StudioDiscover.Source.Api.useSearchPackages)

local Empty = Foundation.Empty
local Loading = Foundation.Loading
local Text = Foundation.Text
local View = Foundation.View

local e = React.createElement

type Props = {
	query: string,
	state: useSearchPackages.SearchState,
}

local function SearchResults(props: Props)
	local state = props.state

	local namingConvention = ReactCharm.useAtom(function()
		return SettingsStore.get().getStorage().namingConvention
	end)

	if state.loading then
		return e(View, {
			tag = "size-full align-x-center align-y-center",
		}, {
			Spinner = e(Loading, {}),
		})
	end

	if state.error ~= nil then
		return e(View, {
			tag = "size-full align-x-center align-y-center padding-large",
		}, {
			Message = e(Text, {
				tag = "auto-xy text-body-medium content-muted",
				Text = `Couldn't load results: {state.error}`,
			}),
		})
	end

	local data = state.data
	if data == nil or #data == 0 then
		return e(View, {
			tag = "size-full align-x-center align-y-center",
		}, {
			EmptyState = e(Empty, {
				text = `No packages matching "{props.query}"`,
			}),
		})
	end

	local cards: { [string]: any } = {}
	for _, pkg in data do
		local displayName = formatName(pkg.name, namingConvention)
		local hasDescription = pkg.description ~= nil and pkg.description:match("%S") ~= nil
		local description = if hasDescription then pkg.description else `{displayName} has no provided description.`
		local latestVersion = pkg.versions[1]

		local nextCardOrder = createNextOrder()
		local nextHeadingOrder = createNextOrder()

		cards[`{pkg.scope}/{pkg.name}`] = e(View, {
			tag = "size-full-0 auto-y col gap-small padding-medium bg-surface-200 radius-medium",
			onActivated = function()
				Navigation.pushScreen("Package", {
					scope = pkg.scope,
					name = pkg.name,
				})
			end,
		}, {
			Heading = e(View, {
				tag = "size-full-0 auto-y row align-y-center gap-small",
				LayoutOrder = nextCardOrder(),
			}, {
				Title = e(Text, {
					tag = "grow auto-y text-title-medium content-emphasis text-align-x-left text-wrap",
					Text = `{pkg.scope}/{pkg.name}`,
					LayoutOrder = nextHeadingOrder(),
				}),
				Version = latestVersion ~= nil and e(Text, {
					tag = "auto-xy text-body-small content-muted",
					Text = `v{latestVersion}`,
					LayoutOrder = nextHeadingOrder(),
				}),
			}),
			Description = e(Text, {
				tag = "size-full-0 auto-y text-body-medium content-muted text-align-x-left text-wrap",
				Text = description,
				LayoutOrder = nextCardOrder(),
			}),
		})
	end

	return e(Content, {}, cards)
end

return SearchResults
