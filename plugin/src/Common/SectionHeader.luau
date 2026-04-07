local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Foundation = require(Packages.Foundation)
local React = require(Packages.React)

local Text = Foundation.Text
local Divider = Foundation.Divider

local e = React.createElement

type SectionHeaderProps = {
	text: string,
	LayoutOrder: number?,
}

local function SectionHeader(props: SectionHeaderProps)
	return e("Frame", {
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
	}, {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
		}),
		Label = e(Text, {
			Text = props.text,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.fromScale(1, 0),
			tag = "text-label-small content-emphasis text-align-x-left",
			LayoutOrder = 1,
		}),
		Underline = e(Divider, { LayoutOrder = 2 }),
	})
end

return SectionHeader
