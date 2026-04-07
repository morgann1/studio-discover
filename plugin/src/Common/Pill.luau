local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Foundation = require(Packages.Foundation)
local React = require(Packages.React)

local View = Foundation.View
local Text = Foundation.Text

local e = React.createElement

type PillProps = {
	text: string,
	LayoutOrder: number?,
	emphasis: boolean?,
}

local function Pill(props: PillProps)
	return e(View, {
		AutomaticSize = Enum.AutomaticSize.XY,
		LayoutOrder = props.LayoutOrder,
		tag = if props.emphasis
			then "bg-surface-300 radius-small padding-xsmall auto-xy"
			else "bg-surface-200 radius-small padding-xsmall auto-xy",
	}, {
		Label = e(Text, {
			Text = props.text,
			AutomaticSize = Enum.AutomaticSize.XY,
			tag = if props.emphasis then "text-caption-small content-emphasis" else "text-caption-small content-muted",
		}),
	})
end

return Pill
