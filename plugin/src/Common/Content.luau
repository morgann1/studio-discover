--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const ScrollView = Foundation.ScrollView
const View = Foundation.View

const e = React.createElement

-- The scrolling, padded column every screen puts its body in.
const function Content(props: {
	read children: React.Node,
})
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
