--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Foundation = require(StudioDiscover.Packages.Foundation)
local Motion = require(StudioDiscover.Packages.Motion)
local React = require(StudioDiscover.Packages.React)
local ReactCharm = require(StudioDiscover.Packages.ReactCharm)

local Navigation = require(StudioDiscover.Source.Navigation)
local SearchStore = require(StudioDiscover.Source.SearchStore)
local SettingsStore = require(StudioDiscover.Source.SettingsStore)

local Item = require(script.Item)
local createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)

local Divider = Foundation.Divider
local IconButton = Foundation.IconButton
local TextInput = Foundation.TextInput
local View = Foundation.View
local ButtonVariant = Foundation.Enums.ButtonVariant
local IconName = Foundation.Enums.IconName
local InputSize = Foundation.Enums.InputSize
local useTokens = Foundation.Hooks.useTokens

local TransitionPreset = Motion.TransitionPreset
local useMotion = Motion.useMotion

local e = React.createElement

type ItemName = "Home" | "Manage" | "Updates" | "Settings" | "About"

type ItemDef = {
	name: ItemName,
	text: string,
	icon: string,
}

local ITEMS: { ItemDef } = table.freeze({
	{ name = "Home" :: ItemName, text = "Home", icon = IconName.House },
	{ name = "Manage" :: ItemName, text = "Installed", icon = IconName.Folder },
	{ name = "Updates" :: ItemName, text = "Updates", icon = IconName.ArrowRotateRight },
	{ name = "Settings" :: ItemName, text = "Settings", icon = IconName.Gear },
	{ name = "About" :: ItemName, text = "About", icon = IconName.CircleI },
}) :: { ItemDef }

local EXPANDED_WIDTH = 252
local COMPACT_WIDTH = 56

type Props = {
	compact: boolean?,
	LayoutOrder: number?,
}

local function Sidebar(props: Props)
	local tokens = useTokens()
	local current = Navigation.useScreen()
	local searchText = SearchStore.useQuery()
	local searchExpanded, setSearchExpanded = React.useState(false)
	local searchBoxRef = React.useRef(nil :: Foundation.TextInputRef?)

	-- Compact mode is temporarily overridden while the user searches via the
	-- search icon; the input expands, auto-focuses, and collapses back on blur.
	local compact = props.compact == true and not searchExpanded

	React.useEffect(function()
		if searchExpanded and searchBoxRef.current then
			searchBoxRef.current.focus()
		end
	end, { searchExpanded })

	local onSearchIconActivated = React.useCallback(function()
		setSearchExpanded(true)
	end, {})

	local onSearchFocusLost = React.useCallback(function()
		setSearchExpanded(false)
	end, {})

	-- Selector-based subscription: Sidebar re-renders only when reduceMotion
	-- flips, not when any other setting changes.
	local reduceMotion = ReactCharm.useAtom(function()
		return SettingsStore.get().getStorage().reduceMotion
	end)

	local states = React.useMemo(function()
		local duration = if reduceMotion then 0 else tokens.Time.Time_200
		local transition = Motion.transition(TransitionPreset.Default, { duration = duration })
		return {
			Expanded = Motion.createState({ width = EXPANDED_WIDTH }, { default = transition }),
			Compact = Motion.createState({ width = COMPACT_WIDTH }, { default = transition }),
		}
	end, { tokens, reduceMotion } :: { any })

	local values, animate = useMotion(states.Expanded)

	React.useEffect(function()
		animate(if compact then states.Compact else states.Expanded)
	end, { compact, states } :: { any })

	local nextOrder = createNextOrder()
	local nextNavOrder = createNextOrder()

	local navItems: { [string]: any } = {}
	for _, item in ITEMS do
		local name = item.name
		local isActive = current.name == name or (current.name == "base" and name == "Home")

		navItems[name] = e(Item, {
			text = item.text,
			icon = item.icon,
			isActive = isActive,
			compact = compact,
			LayoutOrder = nextNavOrder(),
			onActivated = function()
				Navigation.resetScreen(name)
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
			else e(TextInput, {
				textBoxRef = searchBoxRef,
				text = searchText,
				label = "",
				placeholder = "Search",
				leadingIcon = "icons/common/search",
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
			tag = "col",
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = nextOrder(),
		}, navItems),
	})
end

return React.memo(Sidebar)
