--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const ContextProviders = require(StudioDiscover.Source.Common.ContextProviders)
const DisplayNamesScreen = require(StudioDiscover.Source.Screens.DisplayNamesScreen)
const InstalledScreen = require(StudioDiscover.Source.Screens.InstalledScreen)
const Installer = require(StudioDiscover.Source.Installer)
const LayoutContext = require(StudioDiscover.Source.Common.LayoutContext)
const Navigation = require(StudioDiscover.Source.Navigation)
const PackageScreen = require(StudioDiscover.Source.Screens.PackageScreen)
const SearchScreen = require(StudioDiscover.Source.Screens.SearchScreen)
const SettingsScreen = require(StudioDiscover.Source.Screens.SettingsScreen)
const Sidebar = require(StudioDiscover.Source.Common.Sidebar)
const SidebarStore = require(StudioDiscover.Source.SidebarStore)
const SourceScreen = require(StudioDiscover.Source.Screens.SourceScreen)
const buildConfig = require(StudioDiscover.Source.buildConfig)
const exhaustiveMatch = require(StudioDiscover.Libraries.Core.exhaustiveMatch)
const plural = require(StudioDiscover.Source.Util.plural)
const useBreakpoint = require(StudioDiscover.Source.Common.useBreakpoint)

const Divider = Foundation.Divider
const View = Foundation.View
const Breakpoint = Foundation.Enums.Breakpoint
const Orientation = Foundation.Enums.Orientation

const e = React.createElement

-- Keyed by the screen's id, so pushing a screen over one of the same kind mounts it fresh.
const CurrentScreen = React.memo(function()
	const screen = Navigation.useScreen()
	const route = screen.route

	if route.name == "Package" then
		return e(PackageScreen, { key = screen.id, target = route.target })
	elseif route.name == "Source" then
		return e(SourceScreen, { key = screen.id, registry = route.registry })
	elseif route.name == "Installed" then
		return e(InstalledScreen, { key = screen.id, onlyUpdates = false })
	elseif route.name == "Updates" then
		return e(InstalledScreen, { key = screen.id, onlyUpdates = true })
	elseif route.name == "Search" then
		return e(SearchScreen, { key = screen.id })
	elseif route.name == "Settings" then
		return e(SettingsScreen, { key = screen.id })
	elseif route.name == "DisplayNames" then
		return e(DisplayNamesScreen, { key = screen.id })
	end

	return exhaustiveMatch(route.name)
end)

--[[
	The root of the widget. Above Foundation's Small breakpoint the sidebar sits
		beside the screen, unless the user hid it; otherwise the screen fills the
		widget and its header carries the location menu.
]]
const function App(props: {
	read widget: DockWidgetPluginGui,
})
	const widget = props.widget
	const breakpoint = useBreakpoint(widget)
	const isCollapsed = SidebarStore.useIsCollapsed()

	const isWide = breakpoint ~= Breakpoint.XSmall and breakpoint ~= Breakpoint.Small
	const isDocked = not isWide or isCollapsed

	const layout = React.useMemo(function(): LayoutContext.Layout
		return { isWide = isWide, isDocked = isDocked }
	end, { isWide, isDocked } :: { unknown })

	const updatesCount = #Installer.useUpdates().updates
	React.useEffect(function()
		widget.Title = if updatesCount > 0
			then `{buildConfig.widgetTitle} · {plural(updatesCount, "update")}`
			else buildConfig.widgetTitle
	end, { widget, updatesCount } :: { unknown })

	return e(ContextProviders, {
		overlayGui = widget,
	}, {
		Layout = e(LayoutContext.Provider, {
			value = layout,
		}, {
			Root = e(View, {
				tag = "size-full row bg-surface-100",
			}, {
				Sidebar = not isDocked and e(Sidebar, {
					LayoutOrder = 1,
				}),
				Divider = not isDocked and e(Divider, {
					orientation = Orientation.Vertical,
					LayoutOrder = 2,
				}),
				Content = e(View, {
					tag = "size-0-full grow",
					LayoutOrder = 3,
				}, {
					Screen = e(CurrentScreen),
				}),
			}),
		}),
	})
end

return App
