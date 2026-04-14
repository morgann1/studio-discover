local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local React = require(Packages.React)
local StudioComponents = require(Packages.StudioComponents)

local Navigation = require(Discover.Src.UI.Navigation)
local Page = require(Discover.Src.UI.Common.Page)
local useAtom = require(Discover.Src.UI.Common.useAtom)

local Home = require(Discover.Src.UI.Pages.Home)
local Manage = require(Discover.Src.UI.Pages.Manage)
local Overrides = require(Discover.Src.UI.Pages.Overrides)
local Package = require(Discover.Src.UI.Pages.Package)
local Settings = require(Discover.Src.UI.Pages.Settings)

local e = React.createElement
local useCallback = React.useCallback
local useEffect = React.useEffect
local useState = React.useState

local Pages: { [string]: (any) -> any } = {
	Home = Home,
	Manage = Manage,
	Overrides = Overrides,
	Package = Package,
	Settings = Settings,
}

type RenderedScreen = {
	screen: Navigation.Screen,
	component: (any) -> any,
}

local function resolvePage(name: string): (any) -> any
	local component = Pages[name]
	if not component then
		warn(`[Discover] Unknown page: {name}`)
		return Home
	end
	return component
end

type AppProps = {
	plugin: Plugin,
	overlayGui: GuiBase2d,
}

local function App(_props: AppProps)
	local active = useAtom(Navigation.activeScreen)
	local activeId = active.id

	local rendered, setRendered = useState(function(): { RenderedScreen }
		return { { screen = active, component = resolvePage(active.name) } }
	end)

	useEffect(function()
		setRendered(function(prev)
			for _, entry in prev do
				if entry.screen.id == activeId then
					return prev
				end
			end
			local updated = table.clone(prev)
			table.insert(updated, { screen = active, component = resolvePage(active.name) })
			return updated
		end)
	end, { activeId, active } :: { any })

	local removeScreen = useCallback(function(id: string)
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
			pageProps = { options = entry.screen.options },
			onExited = function()
				removeScreen(id)
			end,
		})
	end

	return e(StudioComponents.Background, nil, children)
end

return App
