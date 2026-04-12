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
		tag = if props.emphasis then "bg-surface-300 radius-small auto-xy" else "bg-surface-200 radius-small auto-xy",
	}, {
		Padding = e("UIPadding", {
			PaddingTop = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 4),
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
		}),
		Label = e(Text, {
			Text = props.text,
			AutomaticSize = Enum.AutomaticSize.XY,
			tag = if props.emphasis then "text-caption-small content-emphasis" else "text-caption-small content-muted",
		}),
	})
end

return Pill
