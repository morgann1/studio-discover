--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local React = require(StudioDiscover.Packages.React)

local Content = require(StudioDiscover.Source.Common.Content)
local Screen = require(StudioDiscover.Source.Common.Screen)
local SearchStore = require(StudioDiscover.Source.SearchStore)
local createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)
local useSearchPackages = require(StudioDiscover.Source.Api.useSearchPackages)

local Featured = require(script.Featured)
local Recent = require(script.Recent)
local SearchResults = require(script.SearchResults)

local e = React.createElement

local function HomeScreen()
	local query = SearchStore.useQuery()
	local state = useSearchPackages(query)

	local body: React.ReactNode
	if query == "" then
		local nextOrder = createNextOrder()
		body = e(Content, {}, {
			Featured = e(Featured, {
				LayoutOrder = nextOrder(),
			}),
			Recent = e(Recent, {
				LayoutOrder = nextOrder(),
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
