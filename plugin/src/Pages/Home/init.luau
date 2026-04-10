local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Foundation = require(Packages.Foundation)
local React = require(Packages.React)

local InstalledState = require(Discover.Src.Installer.InstalledStore)
local Installer = require(Discover.Src.Installer.Installer)
local Navigation = require(Discover.Src.Navigation)
local PackageCard = require(Discover.Src.Common.PackageCard)
local ReactHelpers = require(Discover.Src.Common.React)
local SearchState = require(Discover.Src.Wally.SearchStore)
local SettingsModule = require(Discover.Src.Settings)
local useAtom = require(Discover.Src.Common.useAtom)
local useWallyStatusMessage = require(Discover.Src.Wally.useWallyStatus)

local View = Foundation.View
local Text = Foundation.Text
local TextInput = Foundation.TextInput
local ScrollView = Foundation.ScrollView
local IconButton = Foundation.IconButton
local Divider = Foundation.Divider
local Empty = Foundation.Empty
local SystemBanner = Foundation.SystemBanner
local Skeleton = Foundation.Skeleton

local InputSize = Foundation.Enums.InputSize
local ButtonVariant = Foundation.Enums.ButtonVariant
local Visibility = Foundation.Enums.Visibility
local AlertSeverity = Foundation.Enums.AlertSeverity

local e = React.createElement

local function Home()
	local nav = Navigation.useNavigation()
	local results = useAtom(SearchState.results)
	local isLoading = useAtom(SearchState.isLoading)
	local hasSearched = useAtom(SearchState.hasSearched)
	local searchError = useAtom(SearchState.error)
	local installedMap = useAtom(InstalledState.map)

	-- Input value lives locally so typing doesn't re-render the (potentially
	-- huge) results list on every keystroke. We only push to the shared
	-- search atom on commit (Enter / focus lost).
	local searchText, setSearchText = React.useState(function()
		return SearchState.text()
	end)

	-- A ref to settings, refreshed each render, so the install callback below
	-- doesn't need settings in its useCallback deps (which would invalidate
	-- it on every settings change and bust card memoization).
	local settingsCtx = SettingsModule.useSettings()
	local settingsRef = React.useRef(settingsCtx)
	settingsRef.current = settingsCtx

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

	-- Stable callbacks shared across all cards so React.memo can bail out.
	local onCardSelect = React.useCallback(function(scope: string, rawName: string)
		nav.push("Package", { scope = scope, name = rawName })
	end, { nav })

	local onCardInstall = React.useCallback(function(scope: string, rawName: string, version: string)
		task.spawn(function()
			local ctx = settingsRef.current
			local alias = SettingsModule.formatPackageName(rawName, ctx.settings.namingConvention, {
				scope = scope,
				overrides = ctx.settings.nameOverrides,
			})
			local ok, err = Installer.install(scope, rawName, version, alias)
			if not ok then
				warn("[Discover] Install failed:", err)
			end
			InstalledState.refresh()
		end)
	end, {})

	local packageCards = {}
	local cardKey = ReactHelpers.createUniqueKey()
	local nextCardOrder = ReactHelpers.createNextOrder()
	for _, pkg in results do
		local scope = pkg.scope or ""
		local rawName = pkg.name or ""
		local displayName = SettingsModule.formatPackageName(rawName, settingsCtx.settings.namingConvention, {
			scope = scope,
			overrides = settingsCtx.settings.nameOverrides,
		})
		local desc = pkg.description
		if not desc or desc == "" then
			desc = `{displayName} has no provided description.`
		end

		local pkgVersion = pkg.latestVersion
		packageCards[cardKey(`{scope}/{rawName}`)] = e(PackageCard, {
			name = rawName,
			scope = scope,
			description = desc,
			version = pkgVersion,
			realm = pkg.realm,
			depCount = pkg.depCount,
			isInstalled = installedMap[`{scope}/{rawName}`] ~= nil,
			LayoutOrder = nextCardOrder(),
			onSelect = onCardSelect,
			onInstall = onCardInstall,
		})
		packageCards[cardKey(`divider_{scope}/{rawName}`)] = e(Divider, {
			LayoutOrder = nextCardOrder(),
		})
	end

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
		local resultCount = #results .. " packages found"

		local scrollChildren = {
			Layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		}
		for key, card in packageCards do
			scrollChildren[key] = card
		end

		local sectionOrder = ReactHelpers.createNextOrder()
		content = e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
		}, {
			SectionLayout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Header = e(View, {
				Size = UDim2.new(1, 0, 0, 28),
				LayoutOrder = sectionOrder(),
				tag = "bg-surface-200",
			}, {
				Padding = e("UIPadding", {
					PaddingLeft = UDim.new(0, 12),
					PaddingRight = UDim.new(0, 12),
				}),
				HeaderLayout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				Label = e(Text, {
					Text = resultCount,
					AutomaticSize = Enum.AutomaticSize.XY,
					tag = "text-caption-small content-muted",
				}),
			}),
			HeaderDivider = e(Divider, {
				LayoutOrder = sectionOrder(),
			}),
			ListWrap = e("Frame", {
				Size = UDim2.new(1, 0, 1, -29),
				BackgroundTransparency = 1,
				LayoutOrder = sectionOrder(),
			}, {
				List = e(ScrollView, {
					Size = UDim2.fromScale(1, 1),
					scroll = {
						scrollBarVisibility = Visibility.Auto,
						ScrollingDirection = Enum.ScrollingDirection.Y,
						AutomaticCanvasSize = Enum.AutomaticSize.Y,
						CanvasSize = UDim2.new(),
					},
				}, scrollChildren),
			}),
		})
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

	local nextOrder = ReactHelpers.createNextOrder()
	local nextTopBarOrder = ReactHelpers.createNextOrder()
	return e(React.Fragment, nil, {
		TopBar = e(View, {
			Size = UDim2.new(1, 0, 0, 56),
			LayoutOrder = nextOrder(),
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
				PaddingTop = UDim.new(0, 8),
				PaddingBottom = UDim.new(0, 8),
			}),
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
