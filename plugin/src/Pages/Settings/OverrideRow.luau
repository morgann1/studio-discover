local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Foundation = require(Packages.Foundation)
local React = require(Packages.React)

local View = Foundation.View
local Text = Foundation.Text
local IconButton = Foundation.IconButton

local InputSize = Foundation.Enums.InputSize
local ButtonVariant = Foundation.Enums.ButtonVariant

local e = React.createElement

type OverrideRowProps = {
	keyName: string,
	value: string,
	onRemove: (key: string) -> (),
	LayoutOrder: number,
}

local function OverrideRow(props: OverrideRowProps)
	local keyName = props.keyName
	local onRemove = props.onRemove

	local handleRemove = React.useCallback(function()
		onRemove(keyName)
	end, { keyName, onRemove } :: { any })

	return e(View, {
		Size = UDim2.new(1, 0, 0, 24),
		LayoutOrder = props.LayoutOrder,
	}, {
		RowLayout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 6),
		}),
		Label = e(Text, {
			Text = `{keyName} → {props.value}`,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, -32, 0, 0),
			tag = "text-caption-small text-align-x-left text-truncate-end",
			LayoutOrder = 1,
		}),
		Remove = e(IconButton, {
			icon = Foundation.Enums.IconName.Close,
			size = InputSize.Small,
			variant = ButtonVariant.Standard,
			onActivated = handleRemove,
			LayoutOrder = 2,
		}),
	})
end

return OverrideRow
