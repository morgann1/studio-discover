local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Foundation = require(Packages.Foundation)
local React = require(Packages.React)

local View = Foundation.View
local Text = Foundation.Text
local Icon = Foundation.Icon
local Divider = Foundation.Divider
local IconName = Foundation.Enums.IconName
local IconSize = Foundation.Enums.IconSize

local e = React.createElement

type SectionProps = {
	text: string,
	collapsible: boolean?,
	LayoutOrder: number?,
	children: React.ReactNode?,
}

local function Section(props: SectionProps)
	local isExpanded, setExpanded = React.useState(true)
	local collapsible = props.collapsible ~= false

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

		Header = e(View, {
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			tag = "row align-y-center",
			onActivated = if collapsible
				then function()
					setExpanded(function(prev)
						return not prev
					end)
				end
				else nil,
			LayoutOrder = 1,
		}, {
			Layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				HorizontalFlex = Enum.UIFlexAlignment.Fill,
			}),
			Label = e(Text, {
				Text = props.text,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.fromScale(1, 0),
				tag = "text-label-small content-emphasis text-align-x-left",
				LayoutOrder = 1,
			}, {
				Flex = e("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }),
			}),
			Chevron = collapsible and e(Icon, {
				name = if isExpanded then IconName.ChevronLargeDown else IconName.ChevronLargeUp,
				size = IconSize.XSmall,
				LayoutOrder = 2,
			}),
		}),

		Underline = e(Divider, { LayoutOrder = 2 }),

		Content = e("Frame", {
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Visible = isExpanded,
			LayoutOrder = 3,
		}, props.children),
	})
end

return React.memo(Section)
