--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Foundation = require(StudioDiscover.Packages.Foundation)
local React = require(StudioDiscover.Packages.React)
local ReactCharm = require(StudioDiscover.Packages.ReactCharm)

local AboutScreen = require(StudioDiscover.Source.Screens.AboutScreen)
local CompactContext = require(StudioDiscover.Source.Common.CompactContext)
local ContextProviders = require(StudioDiscover.Source.Common.ContextProviders)
local DisplayNamesScreen = require(StudioDiscover.Source.Screens.DisplayNamesScreen)
local HomeScreen = require(StudioDiscover.Source.Screens.HomeScreen)
local ManageScreen = require(StudioDiscover.Source.Screens.ManageScreen)
local Navigation = require(StudioDiscover.Source.Navigation)
local PackageScreen = require(StudioDiscover.Source.Screens.PackageScreen)
local SettingsScreen = require(StudioDiscover.Source.Screens.SettingsScreen)
local SettingsStore = require(StudioDiscover.Source.SettingsStore)
local Sidebar = require(StudioDiscover.Source.Common.Sidebar)
local UpdatesScreen = require(StudioDiscover.Source.Screens.UpdatesScreen)
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

local CurrentScreen = React.memo(function()
	local screen = Navigation.useScreen()

	if screen.name == "Package" then
		return e(PackageScreen)
	elseif screen.name == "Manage" then
		return e(ManageScreen)
	elseif screen.name == "Updates" then
		return e(UpdatesScreen)
	elseif screen.name == "Settings" then
		return e(SettingsScreen)
	elseif screen.name == "DisplayNames" then
		return e(DisplayNamesScreen)
	elseif screen.name == "About" then
		return e(AboutScreen)
	end

	return e(HomeScreen)
end)

local function App(props: Props)
	local nextOrder = createNextOrder()
	local auto = useIsCompact(props.overlayGui)
	local sidebarMode = ReactCharm.useAtom(function()
		return SettingsStore.get().getStorage().sidebarMode
	end)

	local isCompact = if sidebarMode == "Expanded" then false elseif sidebarMode == "Compact" then true else auto

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
