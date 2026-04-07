local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Foundation = require(Packages.Foundation)
local React = require(Packages.React)

local Navigation = require(Discover.Src.Navigation)
local SettingsModule = require(Discover.Src.Settings)
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

local function PageRouter()
	local nav = Navigation.useNavigation()
	local page = Pages[nav.screen.name]

	if not page then
		warn("[Discover] Unknown page:", nav.screen.name)
		page = Home
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		Page = e(page, { key = nav.screen.id }),
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
			Nav = e(Navigation.NavigationProvider, nil, {
				Router = e(PageRouter),
			}),
		}),
	})
end

return App
