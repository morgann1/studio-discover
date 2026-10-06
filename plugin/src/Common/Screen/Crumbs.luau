--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const Navigation = require(StudioDiscover.Source.Navigation)
const SettingsStore = require(StudioDiscover.Source.SettingsStore)
const registryMark = require(StudioDiscover.Source.Util.registryMark)
const routeTitle = require(script.Parent.routeTitle)

const Breadcrumb = Foundation.Breadcrumb
const InputSize = Foundation.Enums.InputSize

const e = React.createElement

-- The way back through every screen on the stack. Each ancestor returns to its screen.
const function Crumbs(props: {
	read stack: { Navigation.Screen },
})
	const settings = SettingsStore.useSettings()

	const items: { Foundation.BreadcrumbItem } = {}
	for index, screen in props.stack do
		const route = screen.route
		const isCurrent = index == #props.stack

		table.insert(items, {
			text = routeTitle(route, settings),
			leading = if route.name == "Source" then registryMark(route.registry) else nil,
			onActivated = if isCurrent
				then nil
				else function()
					Navigation.goBackTo(screen.id)
				end,
		})
	end

	return e(Breadcrumb, {
		items = items,
		size = InputSize.Large,
		maxItems = 3,
	})
end

return Crumbs
