--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const Content = require(StudioDiscover.Source.Common.Content)
const Navigation = require(StudioDiscover.Source.Navigation)
const Screen = require(StudioDiscover.Source.Common.Screen)
const SearchStore = require(StudioDiscover.Source.SearchStore)
const SettingsStore = require(StudioDiscover.Source.SettingsStore)
const createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)
const useSearchPackages = require(StudioDiscover.Source.Api.useSearchPackages)

const Featured = require(script.Featured)
const Recent = require(script.Recent)
const SearchResults = require(script.SearchResults)

const Empty = Foundation.Empty

const e = React.createElement

const function openSettings()
	Navigation.pushScreen({ name = "Settings" })
end

-- Search results while there is a query, otherwise Featured and Recent for the enabled registries.
const function HomeScreen()
	const query = SearchStore.useQuery()
	const state = useSearchPackages(query)
	const registries = SettingsStore.useSettings().registries

	local body: React.Node
	if query ~= "" then
		body = e(SearchResults, {
			query = query,
			state = state,
		})
	elseif not registries.wally and not registries.pesde then
		body = e(Empty, {
			text = "All registries are disabled.",
			button = {
				text = "Open Settings",
				onActivated = openSettings,
			},
		})
	else
		const nextOrder = createNextOrder()

		body = e(Content, {}, {
			Featured = registries.wally and e(Featured, {
				LayoutOrder = nextOrder(),
			}),
			Recent = registries.pesde and e(Recent, {
				LayoutOrder = nextOrder(),
			}),
		})
	end

	return e(Screen, { title = "Home" }, {
		Body = body,
	})
end

return HomeScreen
