--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const ToolButton = require(StudioDiscover.Source.Common.ToolButton)
const iconName = require(StudioDiscover.Source.Util.iconName)

const Menu = Foundation.Menu
const InputSize = Foundation.Enums.InputSize
const PopoverAlign = Foundation.Enums.PopoverAlign

const e = React.createElement

-- One entry in a "…" menu. A disabled entry shows but can't be chosen.
export type MenuAction = {
	read id: string,
	read text: string,
	read isDisabled: boolean?,
	read onActivated: () -> (),
}

-- The "…" button and the menu of `actions` it opens.
const function MoreMenu(props: {
	read actions: { MenuAction },
	read label: string?,
	read LayoutOrder: number?,
})
	const isOpen, setIsOpen = React.useState(false)

	const items: { Foundation.MenuItem } = {}
	for _, action in props.actions do
		table.insert(items, { id = action.id, text = action.text, isDisabled = action.isDisabled })
	end

	const function onActivated(id: string | number)
		setIsOpen(false)

		for _, action in props.actions do
			if action.id == id then
				action.onActivated()
			end
		end
	end

	return e(Menu, {
		isOpen = isOpen,
		items = items,
		size = InputSize.Small,
		align = PopoverAlign.End,
		onActivated = onActivated,
		onPressedOutside = function()
			setIsOpen(false)
		end,
		LayoutOrder = props.LayoutOrder,
	}, {
		Button = e(ToolButton, {
			icon = iconName("ThreeDotsHorizontal"),
			label = props.label or "More",
			onActivated = function()
				setIsOpen(not isOpen)
			end,
		}),
	})
end

return MoreMenu
