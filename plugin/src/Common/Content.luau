--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Foundation = require(StudioDiscover.Packages.Foundation)
local React = require(StudioDiscover.Packages.React)

local ScrollView = Foundation.ScrollView
local View = Foundation.View

local e = React.createElement

type Props = {
	children: React.ReactNode?,
}

local function Content(props: Props)
	return e(ScrollView, {
		tag = "size-full",
		scroll = {
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.fromScale(0, 0),
		},
	}, {
		Inner = e(View, {
			tag = "size-full-0 auto-y col gap-medium padding-large",
		}, props.children),
	})
end

return Content
