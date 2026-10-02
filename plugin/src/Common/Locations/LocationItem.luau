--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const RegistryLogo = require(StudioDiscover.Source.Common.RegistryLogo)
const createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)
const useLocations = require(script.Parent.useLocations)

const Badge = Foundation.Badge
const Icon = Foundation.Icon
const Text = Foundation.Text
const View = Foundation.View
const BadgeVariant = Foundation.Enums.BadgeVariant
const IconName = Foundation.Enums.IconName
const IconSize = Foundation.Enums.IconSize

const e = React.createElement

--[[
	One location row: the source logo when it has one, the name, and the count. The
		sidebar marks the selected row with a fill, and the location menu with a check.
]]
const function LocationItem(props: {
	read location: useLocations.Location,
	read isMenu: boolean,
	read onActivated: () -> (),
	read LayoutOrder: number?,
})
	const location = props.location
	const registry = location.registry
	const count = location.count
	const nextOrder = createNextOrder()

	return e(View, {
		tag = {
			["size-full-800 row align-y-center gap-small padding-x-small radius-medium"] = true,
			["bg-action-soft-emphasis"] = location.isSelected and not props.isMenu,
		},
		onActivated = props.onActivated,
		LayoutOrder = props.LayoutOrder,
	}, {
		Logo = registry ~= nil and e(RegistryLogo, {
			registry = registry,
			size = 18,
			LayoutOrder = nextOrder(),
		}),
		Label = e(Text, {
			tag = {
				["grow auto-y text-body-medium text-align-x-left text-truncate-end"] = true,
				["content-emphasis"] = location.isSelected,
				["content-default"] = not location.isSelected,
			},
			Text = location.text,
			LayoutOrder = nextOrder(),
		}),
		Count = count ~= nil and e(Badge, {
			text = tostring(count),
			variant = if location.isCountEmphasized then BadgeVariant.Emphasis else BadgeVariant.Neutral,
			LayoutOrder = nextOrder(),
		}),
		Check = props.isMenu and location.isSelected and e(Icon, {
			name = IconName.Check,
			size = IconSize.Small,
			LayoutOrder = nextOrder(),
		}),
	})
end

return LocationItem
