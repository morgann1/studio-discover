--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const IconButton = Foundation.IconButton
const Tooltip = Foundation.Tooltip
const ButtonVariant = Foundation.Enums.ButtonVariant
const InputSize = Foundation.Enums.InputSize
const PopoverSide = Foundation.Enums.PopoverSide

const e = React.createElement

-- An icon-only control with its name in a tooltip, as Studio's own plugins label theirs.
const function ToolButton(props: {
	read icon: string,
	read label: string,
	read onActivated: () -> (),
	read isDisabled: boolean?,
	read LayoutOrder: number?,
})
	return e(Tooltip, {
		title = props.label,
		side = PopoverSide.Bottom,
		LayoutOrder = props.LayoutOrder,
	}, {
		Button = e(IconButton, {
			icon = props.icon,
			size = InputSize.Small,
			variant = ButtonVariant.Utility,
			isDisabled = props.isDisabled,
			onActivated = props.onActivated,
		}),
	})
end

return ToolButton
