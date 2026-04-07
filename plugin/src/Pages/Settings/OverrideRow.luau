local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Foundation = require(Packages.Foundation)
local React = require(Packages.React)

local Chip = Foundation.Chip

local ChipSize = Foundation.Enums.ChipSize

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

	return e(Chip, {
		text = `{keyName} → {props.value}`,
		size = ChipSize.Small,
		trailing = {
			iconName = "icons/navigation/close_small",
			onActivated = handleRemove,
		},
		onActivated = handleRemove,
		LayoutOrder = props.LayoutOrder,
	})
end

return OverrideRow
