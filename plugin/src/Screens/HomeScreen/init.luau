--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Foundation = require(StudioDiscover.Packages.Foundation)
local React = require(StudioDiscover.Packages.React)

local Screen = require(StudioDiscover.Source.Common.Screen)
local SearchStore = require(StudioDiscover.Source.SearchStore)
local useSearchPackages = require(StudioDiscover.Source.Api.useSearchPackages)

local SearchResults = require(script.SearchResults)

local Text = Foundation.Text
local View = Foundation.View

local e = React.createElement

local function HomeScreen()
	local query = SearchStore.useQuery()
	local state = useSearchPackages(query)

	local body: React.ReactNode
	if query == "" then
		body = e(View, {
			tag = "size-full",
		}, {
			Label = e(Text, {
				tag = "auto-xy content-muted position-center-center anchor-center-center",
				Text = "Home",
			}),
		})
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
