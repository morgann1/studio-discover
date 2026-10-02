--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const LocationList = require(StudioDiscover.Source.Common.Locations.LocationList)
const RegistryLogo = require(StudioDiscover.Source.Common.RegistryLogo)
const coreTypes = require(StudioDiscover.Libraries.Core.types)
const createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)

const Icon = Foundation.Icon
const Popover = Foundation.Popover
const Text = Foundation.Text
const View = Foundation.View
const IconName = Foundation.Enums.IconName
const IconSize = Foundation.Enums.IconSize
const PopoverAlign = Foundation.Enums.PopoverAlign
const PopoverSide = Foundation.Enums.PopoverSide

const e = React.createElement

const MENU_WIDTH = 240

--[[
	The screen's title, after its source logo when it has one. With `hasMenu`, the
		title opens the location menu, which is how a docked widget switches location.
		`text` is RichText.
]]
const function Title(props: {
	read text: string,
	read registry: coreTypes.Registry?,
	read hasMenu: boolean,
}): React.Node
	const isOpen, setIsOpen = React.useState(false)
	const registry = props.registry
	const nextOrder = createNextOrder()

	const close = React.useCallback(function()
		setIsOpen(false)
	end, {})

	const title = e(View, {
		tag = "auto-xy row align-y-center gap-small",
		onActivated = if props.hasMenu
			then function()
				setIsOpen(not isOpen)
			end
			else nil,
	}, {
		Logo = registry ~= nil and e(RegistryLogo, {
			registry = registry,
			size = 20,
			LayoutOrder = nextOrder(),
		}),
		Text = e(Text, {
			tag = "auto-xy text-heading-small content-emphasis text-truncate-end",
			Text = props.text,
			RichText = true,
			LayoutOrder = nextOrder(),
		}),
		Chevron = props.hasMenu and e(Icon, {
			name = IconName.ChevronSmallDown,
			size = IconSize.Small,
			LayoutOrder = nextOrder(),
		}),
	})

	if not props.hasMenu then
		return title
	end

	return e(Popover.Root, {
		isOpen = isOpen,
	}, {
		Anchor = e(Popover.Anchor, nil, {
			Title = title,
		}),
		Content = e(Popover.Content, {
			side = PopoverSide.Bottom,
			align = PopoverAlign.Start,
			hasArrow = false,
			onPressedOutside = close,
		}, {
			Menu = e(View, {
				tag = "auto-y padding-small",
				Size = UDim2.fromOffset(MENU_WIDTH, 0),
			}, {
				List = e(LocationList, {
					isMenu = true,
					onPicked = close,
				}),
			}),
		}),
	})
end

return Title
