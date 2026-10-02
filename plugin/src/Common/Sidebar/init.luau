--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const LocationList = require(StudioDiscover.Source.Common.Locations.LocationList)
const Navigation = require(StudioDiscover.Source.Navigation)
const SearchStore = require(StudioDiscover.Source.SearchStore)
const SidebarStore = require(StudioDiscover.Source.SidebarStore)
const ToolButton = require(StudioDiscover.Source.Common.ToolButton)
const createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)
const iconName = require(StudioDiscover.Source.Util.iconName)

const ScrollView = Foundation.ScrollView
const SearchInput = Foundation.SearchInput
const View = Foundation.View
const InputSize = Foundation.Enums.InputSize

const e = React.createElement

const WIDTH = 232

-- Typing a query shows the results across every source, wherever the user was.
const function onSearchChanged(text: string)
	SearchStore.setQuery(text)

	if text ~= "" and Navigation.getRoute().name ~= "Search" then
		Navigation.resetScreen({ name = "Search" })
	end
end

-- The sidebar toggle, the search across sources, and the locations.
const function Sidebar(props: {
	read LayoutOrder: number?,
})
	const query = SearchStore.useQuery()
	const nextOrder = createNextOrder()

	return e(View, {
		tag = "size-0-full col gap-medium padding-small",
		Size = UDim2.new(0, WIDTH, 1, 0),
		LayoutOrder = props.LayoutOrder,
	}, {
		Top = e(View, {
			tag = "size-full-0 auto-y row align-y-center gap-small",
			LayoutOrder = nextOrder(),
		}, {
			Toggle = e(ToolButton, {
				icon = iconName("Sidebar"),
				label = "Hide sidebar",
				onActivated = SidebarStore.toggleCollapsed,
				LayoutOrder = 1,
			}),
			Search = e(View, {
				tag = "grow auto-y",
				LayoutOrder = 2,
			}, {
				Input = e(SearchInput, {
					text = query,
					placeholder = "Search all sources",
					size = InputSize.Small,
					width = UDim.new(1, 0),
					onChanged = onSearchChanged,
				}),
			}),
		}),
		Locations = e(ScrollView, {
			tag = "size-full-0 grow",
			scroll = {
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2.fromScale(0, 0),
				ScrollingDirection = Enum.ScrollingDirection.Y,
			},
			LayoutOrder = nextOrder(),
		}, {
			List = e(LocationList, {
				isMenu = false,
			}),
		}),
	})
end

return Sidebar
