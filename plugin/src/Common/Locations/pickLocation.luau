--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Navigation = require(StudioDiscover.Source.Navigation)
const SearchStore = require(StudioDiscover.Source.SearchStore)

--[[
	Switches to a location from the sidebar or the location menu. A location isn't a
		search, so the search box empties to match.
]]
const function pickLocation(route: Navigation.Route)
	SearchStore.setQuery("")
	Navigation.resetScreen(route)
end

return pickLocation
