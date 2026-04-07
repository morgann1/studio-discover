local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Foundation = require(Packages.Foundation)
local React = require(Packages.React)

local Navigation = require(Discover.Src.Navigation)
local PackageCard = require(Discover.Src.Components.PackageCard)
local WallyAPI = require(Discover.Src.Utility.WallyAPI)

local View = Foundation.View
local Text = Foundation.Text
local TextInput = Foundation.TextInput
local ScrollView = Foundation.ScrollView
local IconButton = Foundation.IconButton
local Divider = Foundation.Divider
local Loading = Foundation.Loading
local Empty = Foundation.Empty

local InputSize = Foundation.Enums.InputSize
local ButtonVariant = Foundation.Enums.ButtonVariant
local IconSize = Foundation.Enums.IconSize
local Visibility = Foundation.Enums.Visibility

local e = React.createElement

local function Home()
	local nav = Navigation.useNavigation()
	local searchText, setSearchText = React.useState("")
	local results, setResults = React.useState({} :: { any })
	local isLoading, setIsLoading = React.useState(false)
	local hasSearched, setHasSearched = React.useState(false)

	local searchVersion = React.useRef(0)

	local onSearchChanged = React.useCallback(function(text: string)
		setSearchText(text)

		if text == "" then
			setResults({})
			setHasSearched(false)
			setIsLoading(false)
			searchVersion.current += 1
			return
		end

		setIsLoading(true)
		setHasSearched(true)

		searchVersion.current += 1
		local thisVersion = searchVersion.current

		task.spawn(function()
			local data, err = WallyAPI.search(text)

			if searchVersion.current ~= thisVersion then
				return
			end

			if not data then
				warn("[Discover] Search failed:", err)
				setIsLoading(false)
				setResults({})
				return
			end

			setIsLoading(false)
			setResults(data)

			local pending = #data
			if pending == 0 then
				return
			end

			for _, pkg in data do
				task.spawn(function()
					local meta = WallyAPI.metadata(pkg.scope, pkg.name)
					if searchVersion.current ~= thisVersion then
						return
					end
					if meta and meta.versions then
						local latest = meta.versions[#meta.versions]
						if latest and latest.package then
							pkg.description = latest.package.description
						end
					end
					pending -= 1
					if pending == 0 and searchVersion.current == thisVersion then
						setResults(table.clone(data))
					end
				end)
			end
		end)
	end, {})

	local onSettingsPressed = React.useCallback(function()
		nav.push("Settings")
	end, { nav })

	local packageCards = {}
	for i, pkg in results do
		local scope = pkg.scope or ""
		local name = pkg.name or ""
		local desc = pkg.description
		if not desc or desc == "" then
			desc = `{name} has no provided description.`
		end
		local order = i * 2

		packageCards[scope .. "/" .. name .. "_" .. i] = e(PackageCard, {
			name = name,
			scope = scope,
			description = desc,
			LayoutOrder = order - 1,
			onActivated = function()
				nav.push("Package", { scope = scope, name = name })
			end,
		})
		packageCards["divider_" .. i] = e(Divider, {
			LayoutOrder = order,
		})
	end

	local content
	if isLoading then
		content = e(View, {
			Size = UDim2.fromScale(1, 1),
			tag = "align-x-center align-y-center",
		}, {
			Loader = e(Loading, {
				size = IconSize.Large,
			}),
		})
	elseif hasSearched and #results == 0 then
		content = e(View, {
			Size = UDim2.fromScale(1, 1),
			tag = "align-x-center align-y-center",
		}, {
			EmptyState = e(Empty, {
				icon = "icons/common/search",
			}),
		})
	elseif #results > 0 then
		local resultCount = #results .. " packages found"

		local scrollChildren = {
			Layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Header = e(Text, {
				Text = resultCount,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.fromScale(1, 0),
				tag = "text-caption-small padding-small",
				LayoutOrder = 0,
			}),
		}
		for key, card in packageCards do
			scrollChildren[key] = card
		end

		content = e(ScrollView, {
			Size = UDim2.fromScale(1, 1),
			scroll = {
				scrollBarVisibility = Visibility.Auto,
				ScrollingDirection = Enum.ScrollingDirection.Y,
			},
		}, scrollChildren)
	else
		content = e(View, {
			Size = UDim2.fromScale(1, 1),
			tag = "align-x-center align-y-center",
		}, {
			Prompt = e(Text, {
				Text = "Search for Wally packages",
				tag = "text-label-medium",
			}),
		})
	end

	return e(React.Fragment, nil, {
		TopBar = e(View, {
			Size = UDim2.new(1, 0, 0, 48),
			LayoutOrder = 1,
		}, {
			RowLayout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 8),
			}),
			Padding = e("UIPadding", {
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 8),
				PaddingTop = UDim.new(0, 6),
				PaddingBottom = UDim.new(0, 6),
			}),
			Search = e(TextInput, {
				text = searchText,
				label = "",
				placeholder = "Search packages",
				leadingIcon = "icons/common/search",
				size = InputSize.Medium,
				width = UDim.new(1, -44),
				onChanged = onSearchChanged,
				LayoutOrder = 1,
			}),
			Settings = e(IconButton, {
				icon = Foundation.Enums.IconName.Gear,
				size = InputSize.Medium,
				variant = ButtonVariant.Standard,
				onActivated = onSettingsPressed,
				LayoutOrder = 2,
			}),
		}),

		TopDivider = e(Divider, {
			LayoutOrder = 2,
		}),

		Content = e("Frame", {
			Size = UDim2.new(1, 0, 1, -50),
			BackgroundTransparency = 1,
			LayoutOrder = 3,
		}, {
			Inner = content,
		}),
	})
end

return Home
