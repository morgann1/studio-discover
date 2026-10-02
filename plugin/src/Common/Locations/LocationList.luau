--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const Navigation = require(StudioDiscover.Source.Navigation)
const createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)

const LocationItem = require(script.Parent.LocationItem)
const useLocations = require(script.Parent.useLocations)

const Divider = Foundation.Divider
const Text = Foundation.Text
const View = Foundation.View

const e = React.createElement

--[[
	"This place" and "Sources" with their locations. The location menu separates the
		groups with a divider. `onPicked` runs after a pick switches location.
]]
const function LocationList(props: {
	read isMenu: boolean,
	read onPicked: (() -> ())?,
	read LayoutOrder: number?,
})
	const locations = useLocations()
	const isMenu = props.isMenu
	const nextOrder = createNextOrder()

	const function pick(route: Navigation.Route)
		Navigation.resetScreen(route)

		if props.onPicked ~= nil then
			props.onPicked()
		end
	end

	const function item(location: useLocations.Location, layoutOrder: number): React.Node
		return e(LocationItem, {
			location = location,
			isMenu = isMenu,
			onActivated = function()
				pick(location.route)
			end,
			LayoutOrder = layoutOrder,
		})
	end

	const function group(title: string, groupLocations: { useLocations.Location }): React.Node
		const nextItemOrder = createNextOrder()
		const items: { [string]: React.Node } = {
			Title = e(Text, {
				tag = {
					["size-full-0 auto-y text-align-x-left padding-x-small padding-y-xsmall"] = true,
					["text-title-small content-muted"] = isMenu,
					["text-title-medium content-emphasis"] = not isMenu,
				},
				Text = title,
				LayoutOrder = nextItemOrder(),
			}),
		}

		for _, location in groupLocations do
			items[location.key] = item(location, nextItemOrder())
		end

		return e(View, {
			tag = "size-full-0 auto-y col gap-xxsmall",
			LayoutOrder = nextOrder(),
		}, items)
	end

	const hasSources = #locations.sources > 0

	return e(View, {
		tag = {
			["size-full-0 auto-y col"] = true,
			["gap-small"] = isMenu,
			["gap-large"] = not isMenu,
		},
		LayoutOrder = props.LayoutOrder,
	}, {
		ThisPlace = group("This place", locations.thisPlace),
		SourcesDivider = isMenu and hasSources and e(Divider, { LayoutOrder = nextOrder() }),
		Sources = hasSources and group("Sources", locations.sources),
	})
end

return LocationList
