--!strict

local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Foundation = require(Packages.Foundation)
local React = require(Packages.React)

local Text = Foundation.Text
local Divider = Foundation.Divider

local e = React.createElement

type SettingRowProps = {
	name: string,
	description: string?,
	control: React.ReactNode?,
	footer: React.ReactNode?,
	LayoutOrder: number,
}

local function SettingRow(props: SettingRowProps): React.ReactNode
	return e("Frame", {
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
	}, {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 0),
		}),

		Content = e("Frame", {
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = 1,
		}, {
			Padding = e("UIPadding", {
				PaddingTop = UDim.new(0, 12),
				PaddingBottom = UDim.new(0, 12),
			}),
			RowLayout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				HorizontalFlex = Enum.UIFlexAlignment.Fill,
				Padding = UDim.new(0, 12),
			}),

			Info = e("Frame", {
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = 1,
			}, {
				Flex = e("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }),
				InfoLayout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 4),
				}),
				Name = e(Text, {
					Text = props.name,
					AutomaticSize = Enum.AutomaticSize.Y,
					Size = UDim2.fromScale(1, 0),
					tag = "text-label-small content-emphasis text-align-x-left",
					LayoutOrder = 1,
				}),
				Description = props.description and e(Text, {
					Text = props.description,
					AutomaticSize = Enum.AutomaticSize.Y,
					Size = UDim2.fromScale(1, 0),
					TextWrapped = true,
					tag = "text-caption-small content-muted text-align-x-left",
					LayoutOrder = 2,
				}),
			}),

			Control = props.control and e("Frame", {
				Size = UDim2.fromOffset(0, 0),
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				LayoutOrder = 2,
			}, {
				Flex = e("UIFlexItem", { FlexMode = Enum.UIFlexMode.None }),
				Child = props.control,
			}),
		}),

		Footer = props.footer and e("Frame", {
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = 2,
		}, {
			Padding = e("UIPadding", {
				PaddingBottom = UDim.new(0, 12),
			}),
			Child = props.footer,
		}),

		BottomDivider = e(Divider, {
			LayoutOrder = 3,
		}),
	})
end

return SettingRow
