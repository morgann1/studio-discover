--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const Installer = require(StudioDiscover.Source.Installer)
const LayoutContext = require(StudioDiscover.Source.Common.LayoutContext)
const Navigation = require(StudioDiscover.Source.Navigation)
const SettingsStore = require(StudioDiscover.Source.SettingsStore)
const createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)
const useAtom = require(StudioDiscover.Source.Common.useAtom)

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
]]
const function Screen(props: {
	read title: string?,
	read search: Search?,
	read children: React.Node,
})
	const layout = LayoutContext.useLayout()
	const route = Navigation.useScreen().route
	const namingConvention = useAtom(function()
		return SettingsStore.getSettings().namingConvention
	end)

	const search = props.search
	const nextOrder = createNextOrder()

	return e(View, {
		tag = "size-full col",
	}, {
		Header = e(Header, {
			title = props.title or routeTitle(route, namingConvention),
			registry = if route.name == "Source" then route.registry else nil,
			onRefresh = refresh,
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
