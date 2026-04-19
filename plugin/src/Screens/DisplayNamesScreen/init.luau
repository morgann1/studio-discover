--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local React = require(StudioDiscover.Packages.React)

local Content = require(StudioDiscover.Source.Common.Content)
local Navigation = require(StudioDiscover.Source.Navigation)
local Screen = require(StudioDiscover.Source.Common.Screen)

local e = React.createElement

local function DisplayNamesScreen()
	return e(Screen, {
		title = "Display Names",
		onBack = Navigation.popScreen,
	}, {
		Body = e(Content),
	})
end

return DisplayNamesScreen
