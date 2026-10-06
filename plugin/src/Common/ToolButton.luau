--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const IconButton = Foundation.IconButton
const Tooltip = Foundation.Tooltip
const ButtonVariant = Foundation.Enums.ButtonVariant
const InputSize = Foundation.Enums.InputSize
const PopoverAlign = Foundation.Enums.PopoverAlign
const PopoverSide = Foundation.Enums.PopoverSide

const e = React.createElement

--[[
	An icon-only control with its name in a tooltip, as Studio's own plugins label theirs.

	The tooltip starts at the button's left edge and runs right. A button at the
		trailing edge of the widget passes `isTrailing`, so its tooltip ends at the
		button instead of running past the widget and truncating.
]]
const function ToolButton(props: {
	read icon: string,
	read label: string,
	read onActivated: () -> (),
	read isDisabled: boolean?,
	read isTrailing: boolean?,
	read LayoutOrder: number?,
})
	return e(Tooltip, {
		title = props.label,
		side = PopoverSide.Bottom,
		align = if props.isTrailing then PopoverAlign.End else PopoverAlign.Start,
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
