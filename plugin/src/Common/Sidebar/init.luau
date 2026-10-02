--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const Motion = require(StudioDiscover.Packages.Motion)
const React = require(StudioDiscover.Packages.React)

const Installer = require(StudioDiscover.Source.Installer)
const Navigation = require(StudioDiscover.Source.Navigation)
const SearchStore = require(StudioDiscover.Source.SearchStore)
const SettingsStore = require(StudioDiscover.Source.SettingsStore)

const Item = require(script.Item)
const createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)
const useAtom = require(StudioDiscover.Source.Common.useAtom)
const useTokens = require(StudioDiscover.Source.Common.useTokens)

const Divider = Foundation.Divider
const IconButton = Foundation.IconButton
const SearchInput = Foundation.SearchInput
const View = Foundation.View
const ButtonVariant = Foundation.Enums.ButtonVariant
const IconName = Foundation.Enums.IconName
const InputSize = Foundation.Enums.InputSize

const TransitionPreset = Motion.TransitionPreset
const useMotion = Motion.useMotion

const e = React.createElement

type ItemDef = {
	read name: Navigation.ScreenName,
	read text: string,
	read icon: string,
}

const ITEMS: { ItemDef } = {
	{ name = "Home", text = "Home", icon = IconName.House },
	{ name = "Manage", text = "Installed", icon = IconName.Folder },
	{ name = "Updates", text = "Updates", icon = IconName.ArrowRotateRight },
	{ name = "Settings", text = "Settings", icon = IconName.Gear },
}

const EXPANDED_WIDTH = 252
const COMPACT_WIDTH = 56

--[[
	The search box and the top-level screens. Compact shows icons only, and the
		search icon expands the sidebar until the search box loses focus.
]]
const function Sidebar(props: {
	read compact: boolean,
	read LayoutOrder: number?,
})
	const tokens = useTokens()
	const current = Navigation.useScreen().route.name
	const searchText = SearchStore.useQuery()
	const searchExpanded, setSearchExpanded = React.useState(false)
	const searchBoxRef = React.useRef(nil :: Foundation.TextInputRef?)
	const updatesCount = #Installer.useUpdates().updates
	const reduceMotion = useAtom(function()
		return SettingsStore.getSettings().reduceMotion
	end)

	const compact = props.compact and not searchExpanded

	React.useEffect(function()
		const searchBox = searchBoxRef.current
		if searchExpanded and searchBox ~= nil then
			searchBox.focus()
		end
	end, { searchExpanded })

	-- Results only render on Home, so typing a query from another screen goes there.
	React.useEffect(function()
		if searchText ~= "" and current ~= "Home" then
			Navigation.resetScreen({ name = "Home" })
		end
	end, { searchText })

	const onSearchIconActivated = React.useCallback(function()
		setSearchExpanded(true)
	end, {})

	const onSearchFocusLost = React.useCallback(function()
		setSearchExpanded(false)
	end, {})

	const states = React.useMemo(function()
		const duration = if reduceMotion then 0 else tokens.Time.Time_200
		const transition = Motion.transition(TransitionPreset.Default, { duration = duration })

		return {
			Expanded = Motion.createState({ width = EXPANDED_WIDTH }, { default = transition }),
			Compact = Motion.createState({ width = COMPACT_WIDTH }, { default = transition }),
		}
	end, { tokens, reduceMotion } :: { unknown })

	const values, animate = useMotion(states.Expanded)

	React.useEffect(function()
		animate(if compact then states.Compact else states.Expanded)
	end, { compact, states } :: { unknown })

	const nextOrder = createNextOrder()
	const nextItemOrder = createNextOrder()

	const items: { [string]: React.Node } = {}
	for _, item in ITEMS do
		items[item.name] = e(Item, {
			text = item.text,
			icon = item.icon,
			isActive = current == item.name,
			compact = compact,
			badge = if item.name == "Updates" then updatesCount else nil,
			LayoutOrder = nextItemOrder(),
			onActivated = function()
				Navigation.resetScreen({ name = item.name })
			end,
		})
	end

	return e(View, {
		tag = "col gap-small padding-small bg-surface-100",
		Size = values.width:map(function(width: number)
			return UDim2.new(0, width, 1, 0)
		end),
		LayoutOrder = props.LayoutOrder,
		ZIndex = 3,
	}, {
		Search = if compact
			then e(IconButton, {
				icon = IconName.MagnifyingGlass,
				size = InputSize.Medium,
				variant = ButtonVariant.Text,
				onActivated = onSearchIconActivated,
				LayoutOrder = nextOrder(),
			})
			else e(SearchInput, {
				ref = searchBoxRef,
				text = searchText,
				placeholder = "Search",
				size = InputSize.Medium,
				width = UDim.new(1, 0),
				onChanged = SearchStore.setQuery,
				onFocusLost = onSearchFocusLost,
				LayoutOrder = nextOrder(),
			}),

		Divider = e(Divider, {
			LayoutOrder = nextOrder(),
		}),

		Nav = e(View, {
			tag = "grow col",
			Size = UDim2.fromScale(1, 0),
			LayoutOrder = nextOrder(),
		}, items),
	})
end

return Sidebar
