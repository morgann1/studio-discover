--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Foundation = require(StudioDiscover.Packages.Foundation)
local React = require(StudioDiscover.Packages.React)

local createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)

local Button = Foundation.Button
local TextInput = Foundation.TextInput
local View = Foundation.View
local ButtonVariant = Foundation.Enums.ButtonVariant
local IconName = Foundation.Enums.IconName
local InputSize = Foundation.Enums.InputSize

local e = React.createElement

type Props = {
	name: string,
	displayName: string,
	onNameChanged: (string) -> (),
	onDisplayNameChanged: (string) -> (),
	onRemove: () -> (),
	LayoutOrder: number?,
}

local function Row(props: Props)
	local nextOrder = createNextOrder()

	return e(View, {
		tag = "size-full-0 auto-y row align-y-center gap-small",
		LayoutOrder = props.LayoutOrder,
	}, {
		Name = e(TextInput, {
			text = props.name,
			label = "",
			placeholder = "Package name",
			size = InputSize.Medium,
			width = UDim.new(0.5, -50),
			onChanged = props.onNameChanged,
			LayoutOrder = nextOrder(),
		}),
		DisplayName = e(TextInput, {
			text = props.displayName,
			label = "",
			placeholder = "Display name",
			size = InputSize.Medium,
			width = UDim.new(0.5, -50),
			onChanged = props.onDisplayNameChanged,
			LayoutOrder = nextOrder(),
		}),
		Remove = e(Button, {
			text = "Remove",
			icon = IconName.Trash,
			size = InputSize.Medium,
			variant = ButtonVariant.Utility,
			onActivated = props.onRemove,
			LayoutOrder = nextOrder(),
		}),
	})
end

return Row
