--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)

const Button = Foundation.Button
const TextInput = Foundation.TextInput
const View = Foundation.View
const ButtonVariant = Foundation.Enums.ButtonVariant
const IconName = Foundation.Enums.IconName
const InputSize = Foundation.Enums.InputSize

const e = React.createElement

-- One display-name rule: the package name, the alias to give it, and a Remove button.
const function Row(props: {
	read name: string,
	read displayName: string,
	read onNameChanged: (string) -> (),
	read onDisplayNameChanged: (string) -> (),
	read onRemove: () -> (),
	read LayoutOrder: number?,
})
	const nextOrder = createNextOrder()

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
