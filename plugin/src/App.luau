--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Foundation = require(StudioDiscover.Packages.Foundation)
local React = require(StudioDiscover.Packages.React)
local ReactCharm = require(StudioDiscover.Packages.ReactCharm)

local ChangelogScreen = require(StudioDiscover.Source.Screens.ChangelogScreen)
local CompactContext = require(StudioDiscover.Source.Common.CompactContext)
local ContextProviders = require(StudioDiscover.Source.Common.ContextProviders)
local DisplayNamesScreen = require(StudioDiscover.Source.Screens.DisplayNamesScreen)
local HomeScreen = require(StudioDiscover.Source.Screens.HomeScreen)
local Installer = require(StudioDiscover.Source.Installer)
local ManageScreen = require(StudioDiscover.Source.Screens.ManageScreen)
local Navigation = require(StudioDiscover.Source.Navigation)
local PackageScreen = require(StudioDiscover.Source.Screens.PackageScreen)
local RegistriesScreen = require(StudioDiscover.Source.Screens.RegistriesScreen)
local SettingsScreen = require(StudioDiscover.Source.Screens.SettingsScreen)
local SettingsStore = require(StudioDiscover.Source.SettingsStore)
local Sidebar = require(StudioDiscover.Source.Common.Sidebar)
local UpdatesScreen = require(StudioDiscover.Source.Screens.UpdatesScreen)
local buildConfig = require(StudioDiscover.Generated.buildConfig)
local createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)
local useIsCompact = require(StudioDiscover.Source.Common.useIsCompact)

local Divider = Foundation.Divider
local View = Foundation.View
local Orientation = Foundation.Enums.Orientation

local e = React.createElement

type Props = {
	plugin: Plugin,
	overlayGui: DockWidgetPluginGui,
}

local SCREENS: { [string]: React.ComponentType<any> } = {
	Package = PackageScreen,
	Manage = ManageScreen,
	Updates = UpdatesScreen,
	Settings = SettingsScreen,
	DisplayNames = DisplayNamesScreen,
	Registries = RegistriesScreen,
	Changelog = ChangelogScreen,
}

local CurrentScreen = React.memo(function()
	local screen = Navigation.useScreen()
	return e(SCREENS[screen.name] or HomeScreen)
end)

local function App(props: Props)
	local nextOrder = createNextOrder()
	local auto = useIsCompact(props.overlayGui)
	local sidebarMode = ReactCharm.useAtom(function()
		return SettingsStore.get().getStorage().sidebarMode
	end)

	local isCompact = if sidebarMode == "Expanded" then false elseif sidebarMode == "Compact" then true else auto

	local updatesCount = #Installer.useUpdates().updates
	local widget = props.overlayGui
	React.useEffect(function()
		widget.Title = if updatesCount > 0
			then `{buildConfig.widgetTitle} · {updatesCount} update{if updatesCount == 1 then "" else "s"}`
			else buildConfig.widgetTitle
	end, { widget, updatesCount } :: { any })

	return e(ContextProviders, {
		overlayGui = props.overlayGui :: GuiBase2d,
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
