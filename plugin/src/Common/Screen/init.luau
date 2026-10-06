--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const Installer = require(StudioDiscover.Source.Installer)
const LayoutContext = require(StudioDiscover.Source.Common.LayoutContext)
const Navigation = require(StudioDiscover.Source.Navigation)
const SettingsStore = require(StudioDiscover.Source.SettingsStore)
const createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)

const Header = require(script.Header)
const routeTitle = require(script.routeTitle)

const SearchInput = Foundation.SearchInput
const View = Foundation.View
const InputSize = Foundation.Enums.InputSize

const e = React.createElement

-- The search row a docked screen shows under its header, scoped to that screen.
export type Search = {
	read text: string,
	read placeholder: string,
	read onChanged: (text: string) -> (),
}

const function refresh()
	Installer.refreshInstalledRoots()
	Navigation.refreshScreen()
end

--[[
	The shell of a screen: the header, the search row when docked, and the body.
		`title` is RichText and defaults to the route's name.

	Refresh reloads what was read from the place and the registries. A screen with
		nothing to reload passes `canRefresh = false` to leave it out of the header.
]]
const function Screen(props: {
	read title: string?,
	read search: Search?,
	read canRefresh: boolean?,
	read children: React.Node,
})
	const layout = LayoutContext.useLayout()
	const route = Navigation.useScreen().route
	const settings = SettingsStore.useSettings()

	const search = props.search
	const nextOrder = createNextOrder()

	return e(View, {
		tag = "size-full col",
	}, {
		Header = e(Header, {
			title = props.title or routeTitle(route, settings),
			registry = if route.name == "Source" then route.registry else nil,
			onRefresh = if props.canRefresh == false then nil else refresh,
			LayoutOrder = nextOrder(),
		}),
		Search = layout.isDocked and search ~= nil and e(View, {
			tag = "size-full-0 auto-y padding-x-medium padding-bottom-medium",
			LayoutOrder = nextOrder(),
		}, {
			Input = e(SearchInput, {
				text = search.text,
				placeholder = search.placeholder,
				size = InputSize.Medium,
				width = UDim.new(1, 0),
				onChanged = search.onChanged,
			}),
		}),
		Content = e(View, {
			tag = "size-full-0 grow",
			LayoutOrder = nextOrder(),
		}, props.children),
	})
end

return Screen
