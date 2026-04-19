--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local React = require(StudioDiscover.Packages.React)

local Screen = require(StudioDiscover.Source.Common.Screen)
local SearchStore = require(StudioDiscover.Source.SearchStore)
local useSearchPackages = require(StudioDiscover.Source.Api.useSearchPackages)

local Featured = require(script.Featured)
local SearchResults = require(script.SearchResults)

local e = React.createElement

local function HomeScreen()
	local query = SearchStore.useQuery()
	local state = useSearchPackages(query)

	local body: React.ReactNode
	if query == "" then
		body = e(Featured)
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
