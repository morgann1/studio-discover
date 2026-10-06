--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const LayoutContext = require(StudioDiscover.Source.Common.LayoutContext)
const Navigation = require(StudioDiscover.Source.Navigation)
const SidebarStore = require(StudioDiscover.Source.SidebarStore)
const ToolButton = require(StudioDiscover.Source.Common.ToolButton)
const coreTypes = require(StudioDiscover.Libraries.Core.types)
const createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)
const iconName = require(StudioDiscover.Source.Util.iconName)

const Crumbs = require(script.Parent.Crumbs)
const Title = require(script.Parent.Title)

const HeaderBar = Foundation.HeaderBar
const View = Foundation.View

const e = React.createElement

const function openSettings()
	Navigation.resetScreen({ name = "Settings" })
end

--[[
	The bar above every screen. A screen pushed over another shows the breadcrumb back
		to it instead of a title.

	Expanded, back and forward lead. Docked, the breadcrumb is the way back and the
		title opens the location menu. Refresh, when the screen has one, and Settings
		trail in both, and the sidebar toggle leads whenever the user hid a sidebar
		there is room for.
]]
const function Header(props: {
	read title: string,
	read registry: coreTypes.Registry?,
	read onRefresh: (() -> ())?,
	read LayoutOrder: number?,
})
	const layout = LayoutContext.useLayout()
	const history = Navigation.useHistory()
	const isDocked = layout.isDocked
	const isNested = #history.stack > 1
	const nextLeadingOrder = createNextOrder()
	const nextTrailingOrder = createNextOrder()

	return e(HeaderBar.Root, {
		hasBackground = false,
		LayoutOrder = props.LayoutOrder,
	}, {
		Leading = e(HeaderBar.Leading, nil, {
			Toggle = layout.isWide and isDocked and e(ToolButton, {
				icon = iconName("Sidebar"),
				label = "Show sidebar",
				onActivated = SidebarStore.toggleCollapsed,
				LayoutOrder = nextLeadingOrder(),
			}),
			Back = not isDocked and e(ToolButton, {
				icon = iconName("ChevronLargeLeft"),
				label = "Back",
				isDisabled = not isNested,
				onActivated = Navigation.goBack,
				LayoutOrder = nextLeadingOrder(),
			}),
			Forward = not isDocked and e(ToolButton, {
				icon = iconName("ChevronLargeRight"),
				label = "Forward",
				isDisabled = #history.forward == 0,
				onActivated = Navigation.goForward,
				LayoutOrder = nextLeadingOrder(),
			}),
			Title = e(View, {
				tag = "auto-xy row align-y-center padding-left-xsmall",
				LayoutOrder = nextLeadingOrder(),
			}, {
				Title = if isNested
					then e(Crumbs, {
						stack = history.stack,
					})
					else e(Title, {
						text = props.title,
						registry = props.registry,
						hasMenu = isDocked,
					}),
			}),
		}),
		-- Sized to its tools, so the leading slot keeps the rest of the row for the title.
		Trailing = e(View, {
			tag = "auto-xy row align-y-center gap-small",
			LayoutOrder = 3,
		}, {
			Refresh = props.onRefresh ~= nil and e(ToolButton, {
				icon = iconName("ArrowSpinClockwise"),
				label = "Refresh",
				onActivated = props.onRefresh,
				LayoutOrder = nextTrailingOrder(),
			}),
			Settings = e(ToolButton, {
				icon = iconName("Gear"),
				label = "Settings",
				onActivated = openSettings,
				LayoutOrder = nextTrailingOrder(),
			}),
		}),
	})
end

return Header
