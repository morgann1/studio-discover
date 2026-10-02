--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const CompactContext = require(StudioDiscover.Source.Common.CompactContext)
const ContextProviders = require(StudioDiscover.Source.Common.ContextProviders)
const DisplayNamesScreen = require(StudioDiscover.Source.Screens.DisplayNamesScreen)
const HomeScreen = require(StudioDiscover.Source.Screens.HomeScreen)
const Installer = require(StudioDiscover.Source.Installer)
const ManageScreen = require(StudioDiscover.Source.Screens.ManageScreen)
const Navigation = require(StudioDiscover.Source.Navigation)
const PackageScreen = require(StudioDiscover.Source.Screens.PackageScreen)
const RegistriesScreen = require(StudioDiscover.Source.Screens.RegistriesScreen)
const SettingsScreen = require(StudioDiscover.Source.Screens.SettingsScreen)
const SettingsStore = require(StudioDiscover.Source.SettingsStore)
const Sidebar = require(StudioDiscover.Source.Common.Sidebar)
const UpdatesScreen = require(StudioDiscover.Source.Screens.UpdatesScreen)
const buildConfig = require(StudioDiscover.Source.buildConfig)
const createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)
const useAtom = require(StudioDiscover.Source.Common.useAtom)
const useIsCompact = require(StudioDiscover.Source.Common.useIsCompact)

const Divider = Foundation.Divider
const View = Foundation.View
const Orientation = Foundation.Enums.Orientation

const e = React.createElement

const SCREENS: { [Navigation.ScreenName]: React.ComponentType<{}> } = {
	Home = HomeScreen,
	Manage = ManageScreen,
	Updates = UpdatesScreen,
	Settings = SettingsScreen,
	DisplayNames = DisplayNamesScreen,
	Registries = RegistriesScreen,
}

-- Keyed by the screen's id, so pushing a screen over one of the same kind mounts it fresh.
const CurrentScreen = React.memo(function()
	const screen = Navigation.useScreen()
	const route = screen.route

	if route.name == "Package" then
		return e(PackageScreen, { key = screen.id, target = route.target })
	end

	return e(SCREENS[route.name], { key = screen.id })
end)

-- The root of the widget: the sidebar beside the screen on top of the navigation stack.
const function App(props: {
	read widget: DockWidgetPluginGui,
})
	const widget = props.widget
	const nextOrder = createNextOrder()
	const isWidgetNarrow = useIsCompact(widget)
	const sidebarMode = useAtom(function()
		return SettingsStore.getSettings().sidebarMode
	end)

	const isCompact = if sidebarMode == "Auto" then isWidgetNarrow else sidebarMode == "Compact"

	const updatesCount = #Installer.useUpdates().updates
	React.useEffect(function()
		widget.Title = if updatesCount > 0
			then `{buildConfig.widgetTitle} · {updatesCount} update{if updatesCount == 1 then "" else "s"}`
			else buildConfig.widgetTitle
	end, { widget, updatesCount } :: { unknown })

	return e(ContextProviders, {
		overlayGui = widget,
	}, {
		CompactScope = e(CompactContext.Provider, {
			value = isCompact,
		}, {
			Root = e(View, {
				tag = "size-full row",
			}, {
				Sidebar = e(Sidebar, {
					LayoutOrder = nextOrder(),
					compact = isCompact,
				}),

				Divider = e(Divider, {
					orientation = Orientation.Vertical,
					LayoutOrder = nextOrder(),
				}),

				Content = e(View, {
					tag = "size-0-full grow",
					LayoutOrder = nextOrder(),
				}, {
					Screen = e(CurrentScreen),
				}),
			}),
		}),
	})
end

return App
