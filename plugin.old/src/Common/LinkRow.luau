local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Foundation = require(Packages.Foundation)
local React = require(Packages.React)

local SelectableText = require(Discover.Src.Common.SelectableText)

local Text = Foundation.Text

local e = React.createElement

type LinkRowProps = {
	label: string,
	value: string,
	LayoutOrder: number?,
}

local function LinkRow(props: LinkRowProps)
	return e("Frame", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
	}, {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 8),
		}),
		Label = e(Text, {
			Text = `{props.label}:`,
			AutomaticSize = Enum.AutomaticSize.XY,
			tag = "text-caption-small content-muted",
			LayoutOrder = 1,
		}),
		ValueWrap = e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			LayoutOrder = 2,
		}, {
			Flex = e("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }),
			Value = e(SelectableText, { text = props.value }),
		}),
	})
end

return LinkRow
