--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local React = require(StudioDiscover.Packages.React)

local Content = require(StudioDiscover.Source.Common.Content)
local Screen = require(StudioDiscover.Source.Common.Screen)

local e = React.createElement

local function UpdatesScreen()
	return e(Screen, { title = "Updates" }, {
		Body = e(Content),
	})
end

return UpdatesScreen
