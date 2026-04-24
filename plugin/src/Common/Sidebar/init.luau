--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Foundation = require(StudioDiscover.Packages.Foundation)
local Motion = require(StudioDiscover.Packages.Motion)
local React = require(StudioDiscover.Packages.React)
local ReactCharm = require(StudioDiscover.Packages.ReactCharm)

local Installer = require(StudioDiscover.Source.Installer)
local Navigation = require(StudioDiscover.Source.Navigation)
local SearchStore = require(StudioDiscover.Source.SearchStore)
local SettingsStore = require(StudioDiscover.Source.SettingsStore)

local Item = require(script.Item)
local createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)

local Divider = Foundation.Divider
local IconButton = Foundation.IconButton
local SearchInput = Foundation.SearchInput
local View = Foundation.View
local ButtonVariant = Foundation.Enums.ButtonVariant
local IconName = Foundation.Enums.IconName
local InputSize = Foundation.Enums.InputSize
local useTokens = Foundation.Hooks.useTokens

local TransitionPreset = Motion.TransitionPreset
local useMotion = Motion.useMotion

local e = React.createElement

type ItemName = "Home" | "Manage" | "Updates" | "Changelog" | "Settings"

type ItemDef = {
	name: ItemName,
	text: string,
	icon: string,
}

local TOP_ITEMS: { ItemDef } = table.freeze({
	{ name = "Home" :: ItemName, text = "Home", icon = IconName.House },
	{ name = "Manage" :: ItemName, text = "Installed", icon = IconName.Folder },
	{ name = "Updates" :: ItemName, text = "Updates", icon = IconName.ArrowRotateRight },
	{ name = "Settings" :: ItemName, text = "Settings", icon = IconName.Gear },
}) :: { ItemDef }

local BOTTOM_ITEMS: { ItemDef } = table.freeze({
	{ name = "Changelog" :: ItemName, text = "Changelog", icon = IconName.RectangleList },
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

	local compact = props.compact == true and not searchExpanded

	React.useEffect(function()
		if searchExpanded and searchBoxRef.current then
			searchBoxRef.current.focus()
		end
	end, { searchExpanded })

	React.useEffect(function()
		if searchText ~= "" and current.name ~= "Home" then
			Navigation.resetScreen("Home")
		end
	end, { searchText })

	local onSearchIconActivated = React.useCallback(function()
		setSearchExpanded(true)
	end, {})

	local onSearchFocusLost = React.useCallback(function()
		setSearchExpanded(false)
	end, {})

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

	local updatesState = Installer.useUpdates()
	local updatesCount = #updatesState.updates

	local nextOrder = createNextOrder()

	local function renderNavItems(items: { ItemDef }): { [string]: any }
		local result: { [string]: any } = {}
		local order = createNextOrder()
		for _, item in items do
			local name = item.name
			local isActive = current.name == name or (current.name == "base" and name == "Home")

			result[name] = e(Item, {
				text = item.text,
				icon = item.icon,
				isActive = isActive,
				compact = compact,
				badge = if name == "Updates" then updatesCount else nil,
				LayoutOrder = order(),
				onActivated = function()
					Navigation.resetScreen(name)
				end,
			})
		end
		return result
	end

	local topItems = renderNavItems(TOP_ITEMS)
	local bottomItems = renderNavItems(BOTTOM_ITEMS)

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
				ref = searchBoxRef :: any,
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
		}, {
			Top = e(View, {
				tag = "size-full-0 auto-y col",
				LayoutOrder = 1,
			}, topItems),

			Spacer = e(View, {
				tag = "grow",
				Size = UDim2.fromScale(1, 0),
				LayoutOrder = 2,
			}),

			Bottom = e(View, {
				tag = "size-full-0 auto-y col",
				LayoutOrder = 3,
			}, bottomItems),
		}),
	})
end

return React.memo(Sidebar)
