local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Foundation = require(Packages.Foundation)
local React = require(Packages.React)

local Navigation = require(Discover.Src.Navigation)
local Page = require(Discover.Src.Common.Page)
local SettingsModule = require(Discover.Src.Settings)
local UpdateChecker = require(Discover.Src.UpdateChecker)
local useStudioTheme = require(Discover.Src.Common.useStudioTheme)

local Home = require(Discover.Src.Pages.Home)
local Manage = require(Discover.Src.Pages.Manage)
local Package = require(Discover.Src.Pages.Package)
local Settings = require(Discover.Src.Pages.Settings)

local e = React.createElement

local Pages = {
	Home = Home,
	Package = Package,
	Settings = Settings,
	Manage = Manage,
}

type RenderedScreen = {
	screen: Navigation.Screen,
	component: any,
}

local function PageRouter()
	local nav = Navigation.useNavigation()
	local activeId = nav.screen.id

	local rendered, setRendered = React.useState(function(): { RenderedScreen }
		return { { screen = nav.screen, component = Pages[nav.screen.name] or Home } }
	end)

	React.useEffect(function()
		setRendered(function(prev)
			for _, entry in prev do
				if entry.screen.id == activeId then
					return prev
				end
			end
			local component = Pages[nav.screen.name]
			if not component then
				warn("[Discover] Unknown page:", nav.screen.name)
				component = Home
			end
			local next = table.clone(prev)
			table.insert(next, { screen = nav.screen, component = component })
			return next
		end)
	end, { activeId, nav.screen } :: { any })

	local removeScreen = React.useCallback(function(id: string)
		setRendered(function(prev)
			local next = {}
			for _, entry in prev do
				if entry.screen.id ~= id then
					table.insert(next, entry)
				end
			end
			return next
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

local function AppContent()
	local ctx = SettingsModule.useSettings()
	local isEnabled = ctx.settings.checkForUpdates
	local update = UpdateChecker.useUpdateChecker(isEnabled)

	local isDismissed = update ~= nil and ctx.settings.dismissedUpdateVersion == update.version

	local onDismiss = React.useCallback(function()
		if update then
			ctx.setSetting("dismissedUpdateVersion", update.version)
		end
	end, { update, ctx } :: { any })

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

local function App(props: { plugin: Plugin?, overlayGui: Instance? })
	local theme = useStudioTheme()
	return e(Foundation.FoundationProvider, {
		theme = theme,
		device = "Desktop",
		plugin = props.plugin,
		overlayGui = props.overlayGui,
	}, {
		Settings = e(SettingsModule.SettingsProvider, { plugin = props.plugin }, {
			AppContent = e(AppContent),
		}),
	})
end

return App
