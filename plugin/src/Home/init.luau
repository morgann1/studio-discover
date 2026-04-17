local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Foundation = require(Packages.Foundation)
local React = require(Packages.React)

local Navigation = require(Discover.Src.Navigation)
local PackageList = require(script.PackageList)
local PopularPackages = require(script.PopularPackages)
local SearchState = require(Discover.Src.SearchStore)
local SettingsModule = require(Discover.Src.Settings.SettingsStore)
local TopBar = require(Discover.Src.Common.TopBar)
local createNextOrder = require(Discover.Src.Util.createNextOrder)
local useAtom = require(Discover.Src.Common.useAtom)
local useWallyStatusMessage = require(Discover.Src.Api.useWallyStatus)

local View = Foundation.View
local Text = Foundation.Text
local TextInput = Foundation.TextInput
local IconButton = Foundation.IconButton
local Divider = Foundation.Divider
local Empty = Foundation.Empty
local SystemBanner = Foundation.SystemBanner
local Skeleton = Foundation.Skeleton

local InputSize = Foundation.Enums.InputSize
local ButtonVariant = Foundation.Enums.ButtonVariant
local AlertSeverity = Foundation.Enums.AlertSeverity

local e = React.createElement

local function Home()
	local nav = Navigation.useNavigation()
	local results = useAtom(SearchState.results)
	local isLoading = useAtom(SearchState.isLoading)
	local hasSearched = useAtom(SearchState.hasSearched)
	local searchError = useAtom(SearchState.error)
	local searchText, setSearchText = React.useState(function()
		return SearchState.text()
	end)

	local settingsCtx = SettingsModule.useSettings()

	local onSearchChanged = React.useCallback(function(text: string)
		setSearchText(text)
	end, {})

	local onSearchCommit = React.useCallback(function()
		SearchState.run(searchText)
	end, { searchText })

	local onSettingsPressed = React.useCallback(function()
		nav.push("Settings")
	end, { nav })

	local onManagePressed = React.useCallback(function()
		nav.push("Manage")
	end, { nav })

	local wallyWaitMessage = useWallyStatusMessage()

	local onCardSelect = React.useCallback(function(scope: string, rawName: string)
		nav.push("Package", { scope = scope, name = rawName })
	end, { nav })

	local content
	if searchError then
		content = e(View, {
			Size = UDim2.fromScale(1, 1),
		}, {
			Padding = e("UIPadding", {
				PaddingLeft = UDim.new(0, 16),
				PaddingRight = UDim.new(0, 16),
				PaddingTop = UDim.new(0, 16),
			}),
			Banner = e(SystemBanner, {
				severity = AlertSeverity.Error,
				title = "Couldn't reach Wally",
				description = searchError,
			}),
		})
	elseif isLoading then
		local skeletonChildren = {
			Layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8),
			}),
			Padding = e("UIPadding", {
				PaddingLeft = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 12),
				PaddingTop = UDim.new(0, 12),
			}),
		}
		if wallyWaitMessage then
			skeletonChildren.WaitMessage = e(Text, {
				Text = wallyWaitMessage,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.fromScale(1, 0),
				tag = "text-caption-small text-align-x-left",
				LayoutOrder = 0,
			})
		end
		for i = 1, 5 do
			skeletonChildren[`skeleton_{i}`] = e(Skeleton, {
				Size = UDim2.new(1, 0, 0, 64),
				LayoutOrder = i,
			})
		end
		content = e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
		}, skeletonChildren)
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
		local items = {}
		for _, result in results do
			local displayName =
				SettingsModule.formatPackageName(result.name or "", settingsCtx.settings.namingConvention, {
					overrides = settingsCtx.settings.nameOverrides,
				})
			local description = result.description
			if not description or description == "" then
				description = `{displayName} has no provided description.`
			end
			table.insert(items, {
				scope = result.scope or "",
				name = result.name or "",
				description = description,
				version = result.latestVersion,
				realm = result.realm,
				dependencyCount = result.depCount,
			})
		end
		content = e(PackageList, {
			header = `{#results} packages found`,
			items = items,
			onSelect = onCardSelect,
		})
	else
		content = e(PackageList, {
			header = "Popular packages",
			items = PopularPackages,
			onSelect = onCardSelect,
		})
	end

	local nextOrder = createNextOrder()
	local nextTopBarOrder = createNextOrder()
	return e(React.Fragment, nil, {
		TopBar = e(TopBar, {
			LayoutOrder = nextOrder(),
		}, {
			SearchWrap = e("Frame", {
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = nextTopBarOrder(),
			}, {
				Flex = e("UIFlexItem", {
					FlexMode = Enum.UIFlexMode.Fill,
				}),
				Search = e(TextInput, {
					text = searchText,
					label = "",
					placeholder = "Search packages",
					leadingIcon = "icons/common/search",
					size = InputSize.Medium,
					width = UDim.new(1, 0),
					onChanged = onSearchChanged,
					onReturnPressed = onSearchCommit,
					onFocusLost = onSearchCommit,
				}),
			}),
			Manage = e(IconButton, {
				icon = Foundation.Enums.IconName.Folder,
				size = InputSize.Medium,
				variant = ButtonVariant.Standard,
				onActivated = onManagePressed,
				LayoutOrder = nextTopBarOrder(),
			}),
			Settings = e(IconButton, {
				icon = Foundation.Enums.IconName.Gear,
				size = InputSize.Medium,
				variant = ButtonVariant.Standard,
				onActivated = onSettingsPressed,
				LayoutOrder = nextTopBarOrder(),
			}),
		}),

		TopDivider = e(Divider, {
			LayoutOrder = nextOrder(),
		}),

		Content = e("Frame", {
			Size = UDim2.new(1, 0, 1, -58),
			BackgroundTransparency = 1,
			LayoutOrder = nextOrder(),
		}, {
			Inner = content,
		}),
	})
end

return Home
