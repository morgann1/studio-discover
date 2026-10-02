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
const MoreMenu = require(script.Parent.MoreMenu)
const Title = require(script.Parent.Title)
const types = require(script.Parent.types)

const HeaderBar = Foundation.HeaderBar
const View = Foundation.View

const e = React.createElement

--[[
	The bar above every screen. A screen pushed over another shows the breadcrumb back
		to it instead of a title.

	Expanded, back and forward lead, and refresh sits beside the "…" menu. Docked,
		the breadcrumb is the way back, the title opens the location menu, and refresh
		moves into the "…" menu. The sidebar toggle leads whenever the user hid a
		sidebar there is room for.
]]
const function Header(props: {
	read title: string,
	read registry: coreTypes.Registry?,
	read actions: { types.MenuAction },
	read onRefresh: () -> (),
	read LayoutOrder: number?,
})
	const layout = LayoutContext.useLayout()
	const history = Navigation.useHistory()
	const isDocked = layout.isDocked
	const isNested = #history.stack > 1
	const nextLeadingOrder = createNextOrder()
	const nextTrailingOrder = createNextOrder()

	const actions = table.clone(props.actions)
	if isDocked then
		table.insert(actions, 1, { id = "refresh", text = "Refresh", onActivated = props.onRefresh })
	end

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
			Refresh = not isDocked and e(ToolButton, {
				icon = iconName("ArrowSpinClockwise"),
				label = "Refresh",
				onActivated = props.onRefresh,
				LayoutOrder = nextTrailingOrder(),
			}),
			More = e(MoreMenu, {
				actions = actions,
				LayoutOrder = nextTrailingOrder(),
			}),
		}),
	})
end

return Header
