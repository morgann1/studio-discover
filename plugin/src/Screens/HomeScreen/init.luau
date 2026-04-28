--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Foundation = require(StudioDiscover.Packages.Foundation)
local React = require(StudioDiscover.Packages.React)

local Content = require(StudioDiscover.Source.Common.Content)
local Navigation = require(StudioDiscover.Source.Navigation)
local Screen = require(StudioDiscover.Source.Common.Screen)
local SearchStore = require(StudioDiscover.Source.SearchStore)
local SettingsStore = require(StudioDiscover.Source.SettingsStore)
local createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)
local useSearchPackages = require(StudioDiscover.Source.Api.useSearchPackages)

local Featured = require(script.Featured)
local Recent = require(script.Recent)
local SearchResults = require(script.SearchResults)

local Empty = Foundation.Empty

local e = React.createElement

local function HomeScreen()
	local query = SearchStore.useQuery()
	local state = useSearchPackages(query)
	local registries = SettingsStore.useSettings().registries

	local onOpenSettings = React.useCallback(function()
		Navigation.pushScreen("Settings")
	end, {})

	local body: React.ReactNode
	if query == "" then
		if not registries.wally and not registries.pesde then
			body = e(Empty, {
				text = "All registries are disabled.",
				button = {
					text = "Open Settings",
					onActivated = onOpenSettings,
				},
			})
		else
			local nextOrder = createNextOrder()
			local children: { [string]: any } = {}
			if registries.wally then
				children.Featured = e(Featured, {
					LayoutOrder = nextOrder(),
				})
			end
			if registries.pesde then
				children.Recent = e(Recent, {
					LayoutOrder = nextOrder(),
				})
			end
			body = e(Content, {}, children)
		end
	else
		body = e(SearchResults, {
			query = query,
			state = state,
		})
	end

	return e(Screen, { title = "Home" }, {
		Body = body,
	})
end

return HomeScreen
