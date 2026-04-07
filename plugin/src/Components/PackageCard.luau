local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Foundation = require(Packages.Foundation)
local React = require(Packages.React)

local View = Foundation.View
local Text = Foundation.Text
local Icon = Foundation.Icon

local IconSize = Foundation.Enums.IconSize

local e = React.createElement

type PackageCardProps = {
	name: string,
	scope: string,
	description: string?,
	onActivated: (() -> ())?,
	LayoutOrder: number?,
}

local function PackageCard(props: PackageCardProps)
	local onActivated = React.useCallback(function()
		if props.onActivated then
			props.onActivated()
		end
	end, { props.onActivated })

	return e(View, {
		Size = UDim2.new(1, 0, 0, 56),
		onActivated = onActivated,
		LayoutOrder = props.LayoutOrder,
	}, {
		RowLayout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 10),
		}),
		Padding = e("UIPadding", {
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
		}),

		Info = e("Frame", {
			Size = UDim2.new(1, -36, 1, 0),
			BackgroundTransparency = 1,
			LayoutOrder = 1,
		}, {
			InfoLayout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 2),
			}),
			Title = e(Text, {
				Text = `{props.scope}/{props.name}`,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.fromScale(1, 0),
				tag = "text-label-medium content-emphasis text-truncate-end text-align-x-left",
				LayoutOrder = 1,
			}),
			Description = e(Text, {
				Text = props.description or "",
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.fromScale(1, 0),
				tag = "text-caption-small text-truncate-end text-align-x-left",
				LayoutOrder = 2,
			}),
		}),

		Arrow = e(Icon, {
			name = Foundation.Enums.IconName.ChevronSmallRight,
			size = IconSize.Small,
			LayoutOrder = 2,
		}),
	})
end

return PackageCard
