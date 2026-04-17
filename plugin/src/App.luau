--!strict

local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Foundation = require(Packages.Foundation)
local HomePage = require(Discover.Src.Pages.HomePage)
local ManagePage = require(Discover.Src.Pages.ManagePage)
local Navigation = require(Discover.Src.Navigation)
local OverridesPage = require(Discover.Src.Pages.OverridesPage)
local PackagePage = require(Discover.Src.Pages.PackagePage)
local Page = require(Discover.Src.Common.Page)
local React = require(Packages.React)
local SettingsModule = require(Discover.Src.SettingsStore)
local SettingsPage = require(Discover.Src.Pages.SettingsPage)
local useStudioTheme = require(Discover.Src.Common.useStudioTheme)
local useUpdateChecker = require(Discover.Src.UpdateChecker)

local e = React.createElement

local Pages: { [string]: any? } = {
	Home = HomePage,
	Manage = ManagePage,
	Overrides = OverridesPage,
	Package = PackagePage,
	Settings = SettingsPage,
}

type RenderedScreen = {
	screen: Navigation.Screen,
	component: any,
}

local function PageRouter()
	local nav = Navigation.useNavigation()
	local activeId = nav.screen.id

	local rendered, setRendered = React.useState(function(): { RenderedScreen }
		return { { screen = nav.screen, component = Pages[nav.screen.name] or HomePage } }
	end)

	React.useEffect(function()
		setRendered(function(prev)
			for _, entry in prev do
				if entry.screen.id == activeId then
					return prev
				end
			end
			local component = Pages[nav.screen.name]
			if component == nil then
				warn("[Discover] Unknown page:", nav.screen.name)
				component = HomePage
			end
			local updated = table.clone(prev)
			table.insert(updated, { screen = nav.screen, component = component })
			return updated
		end)
	end, { activeId, nav.screen } :: { any })

	local removeScreen = React.useCallback(function(id: string)
		setRendered(function(prev)
			local filtered = {}
			for _, entry in prev do
				if entry.screen.id ~= id then
					table.insert(filtered, entry)
				end
			end
			return filtered
		end)
	end, {})

	local children: { [string]: any } = {}
	for _, entry in rendered do
		local id = entry.screen.id
		children[id] = e(Page, {
			active = id == activeId,
			component = entry.component,
			pageProps = { key = id },
			onExited = function()
				removeScreen(id)
			end,
		})
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, children)
end

local SystemBanner = Foundation.SystemBanner
local AlertSeverity = Foundation.Enums.AlertSeverity

local function useWidgetEnabled(widget: Instance?): boolean
	local enabled, setEnabled = React.useState(function()
		if widget ~= nil and (widget :: any).Enabled ~= nil then
			return (widget :: any).Enabled
		end
		return true
	end)

	React.useEffect(function(): (() -> ())?
		if widget == nil then
			return nil
		end
		local gui = widget :: DockWidgetPluginGui
		local connection = gui:GetPropertyChangedSignal("Enabled"):Connect(function()
			setEnabled(gui.Enabled)
		end)
		return function()
			connection:Disconnect()
		end
	end, { widget })

	return enabled
end

local function AppContent(props: { overlayGui: Instance? })
	local settingsContext = SettingsModule.useSettings()
	local isEnabled = settingsContext.settings.checkForUpdates
	local widgetEnabled = useWidgetEnabled(props.overlayGui)
	local update = useUpdateChecker(isEnabled, widgetEnabled)

	local isDismissed = update ~= nil and settingsContext.settings.dismissedUpdateVersion == update.version

	local onDismiss = React.useCallback(function()
		if update ~= nil then
			settingsContext.setSetting("dismissedUpdateVersion", update.version)
		end
	end, { update, settingsContext } :: { any })

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),

		UpdateBanner = update and not isDismissed and e("Frame", {
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = 1,
		}, {
			Padding = e("UIPadding", {
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 8),
				PaddingTop = UDim.new(0, 8),
			}),
			Banner = e(SystemBanner, {
				severity = AlertSeverity.Info,
				title = `Discover v{update.version} is available`,
				description = "Visit GitHub releases to download the latest version.",
				onClose = onDismiss,
			}),
		}),

		Content = e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			LayoutOrder = 2,
		}, {
			Flex = e("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }),
			Nav = e(Navigation.NavigationProvider, nil, {
				Router = e(PageRouter),
			}),
		}),
	})
end

local function App(props: { plugin: Plugin?, overlayGui: Instance? }): React.ReactNode
	local theme = useStudioTheme()
	return e(Foundation.FoundationProvider, {
		theme = theme,
		device = "Desktop",
		plugin = props.plugin,
		overlayGui = props.overlayGui,
	}, {
		Settings = e(SettingsModule.SettingsProvider, { plugin = props.plugin }, {
			AppContent = e(AppContent, { overlayGui = props.overlayGui }),
		}),
	})
end

return App
