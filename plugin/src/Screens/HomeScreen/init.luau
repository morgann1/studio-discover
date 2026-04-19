--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Foundation = require(StudioDiscover.Packages.Foundation)
local React = require(StudioDiscover.Packages.React)

local Screen = require(StudioDiscover.Source.Common.Screen)

local Text = Foundation.Text
local View = Foundation.View

local e = React.createElement

local function HomeScreen()
	return e(Screen, { title = "Home" }, {
		Placeholder = e(View, {
			tag = "size-full",
		}, {
			Label = e(Text, {
				tag = "auto-xy content-muted position-center-center anchor-center-center",
				Text = "Home",
			}),
		}),
	})
end

return HomeScreen
