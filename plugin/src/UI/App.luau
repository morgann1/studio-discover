local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local React = require(Packages.React)
local StudioComponents = require(Packages.StudioComponents)

local Navigation = require(Discover.Src.UI.Navigation)
local Page = require(Discover.Src.UI.Common.Page)
local Sidebar = require(Discover.Src.UI.Common.Sidebar)
local lucideIconProps = require(Discover.Src.UI.Common.lucideIconProps)
local useAtom = require(Discover.Src.UI.Common.useAtom)

local About = require(Discover.Src.UI.Pages.About)
local Home = require(Discover.Src.UI.Pages.Home)
local Installed = require(Discover.Src.UI.Pages.Installed)
local Overrides = require(Discover.Src.UI.Pages.Overrides)
local Package = require(Discover.Src.UI.Pages.Package)
local Settings = require(Discover.Src.UI.Pages.Settings)
local Updates = require(Discover.Src.UI.Pages.Updates)

local useTheme = StudioComponents.useTheme

local e = React.createElement
local useCallback = React.useCallback
local useEffect = React.useEffect
local useState = React.useState

-- Keep HEADER_HEIGHT aligned with the sidebar search row's height so the
-- header divider and the sidebar search separator render on the same Y.
local HEADER_HEIGHT = 38
local HEADER_DIVIDER_HEIGHT = 1
local HEADER_TITLE_TEXT_SIZE = 18

local Pages: { [string]: (any) -> any } = {
	About = About,
	Home = Home,
	Installed = Installed,
	Overrides = Overrides,
	Package = Package,
	Settings = Settings,
	Updates = Updates,
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
	local theme = useTheme()
	local active = useAtom(Navigation.activeScreen)
	local stack = useAtom(Navigation.stack)
	local activeId = active.id
	local canGoBack = #stack > 1

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

	return e(StudioComponents.Background, nil, {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),

		SidebarPanel = e(Sidebar),

		ContentWrap = e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			LayoutOrder = 2,
		}, {
			Flex = e("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }),
			Layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			Header = e("Frame", {
				Size = UDim2.new(1, 0, 0, HEADER_HEIGHT),
				BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
				BorderSizePixel = 0,
				LayoutOrder = 1,
			}, {
				Padding = e("UIPadding", {
					PaddingLeft = UDim.new(0, 10),
					PaddingRight = UDim.new(0, 10),
					PaddingTop = UDim.new(0, 4),
					PaddingBottom = UDim.new(0, 4),
				}),
				Layout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 8),
				}),
				Back = if canGoBack
					then e(StudioComponents.Button, {
						Icon = lucideIconProps("arrow-left"),
						Size = UDim2.fromOffset(28, 24),
						OnActivated = Navigation.pop,
						LayoutOrder = 1,
					})
					else nil,
				Title = e("TextLabel", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Font = Enum.Font.SourceSansSemibold,
					TextSize = HEADER_TITLE_TEXT_SIZE,
					TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Center,
					Text = active.name,
					LayoutOrder = 2,
				}),
			}),

			HeaderDivider = e("Frame", {
				Size = UDim2.new(1, 0, 0, HEADER_DIVIDER_HEIGHT),
				BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
				BorderSizePixel = 0,
				LayoutOrder = 2,
			}),

			PageArea = e("Frame", {
				Size = UDim2.new(1, 0, 1, -HEADER_HEIGHT - HEADER_DIVIDER_HEIGHT),
				BackgroundTransparency = 1,
				ClipsDescendants = true,
				LayoutOrder = 3,
			}, children),
		}),
	})
end

return App
