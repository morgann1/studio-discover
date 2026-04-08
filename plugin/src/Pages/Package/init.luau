local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Foundation = require(Packages.Foundation)
local React = require(Packages.React)

local DependencyGroup = require(script.DependencyGroup)
local InstalledPackages = require(Discover.Src.Installer.InstalledPackages)
local InstalledState = require(Discover.Src.Installer.InstalledStore)
local Installer = require(Discover.Src.Installer.Installer)
local LinkRow = require(Discover.Src.Common.LinkRow)
local Navigation = require(Discover.Src.Navigation)
local Pill = require(Discover.Src.Common.Pill)
local ReactHelpers = require(Discover.Src.Common.React)
local SectionHeader = require(Discover.Src.Common.SectionHeader)
local SelectableText = require(Discover.Src.Common.SelectableText)
local SettingsModule = require(Discover.Src.Settings)
local WallyAPI = require(Discover.Src.Wally.Api)
local useAtom = require(Discover.Src.Common.useAtom)
local useWallyStatusMessage = require(Discover.Src.Wally.useWallyStatus)

local View = Foundation.View
local Text = Foundation.Text
local Button = Foundation.Button
local IconButton = Foundation.IconButton
local Divider = Foundation.Divider
local ScrollView = Foundation.ScrollView
local Loading = Foundation.Loading
local SystemBanner = Foundation.SystemBanner
local Dropdown = Foundation.Dropdown

local InputSize = Foundation.Enums.InputSize
local ButtonVariant = Foundation.Enums.ButtonVariant
local IconSize = Foundation.Enums.IconSize
local Visibility = Foundation.Enums.Visibility
local AlertSeverity = Foundation.Enums.AlertSeverity

local e = React.createElement

local function Package()
	local nav = Navigation.useNavigation()
	local screen = nav.screen
	local scope = screen.options and screen.options.scope or ""
	local rawName = screen.options and screen.options.name or ""
	local ctx = SettingsModule.useSettings()

	local allVersions: { any }?, setAllVersions = React.useState(nil :: { any }?)
	local selectedVersion: string?, setSelectedVersion = React.useState(nil :: string?)
	local isLoading, setIsLoading = React.useState(true)

	React.useEffect(function()
		setIsLoading(true)
		task.spawn(function()
			local data = WallyAPI.metadata(scope, rawName)
			if data and data.versions and #data.versions > 0 then
				setAllVersions(data.versions)
				setSelectedVersion(data.versions[1].package.version)
			end
			setIsLoading(false)
		end)
		return nil
	end, { scope, rawName })

	local metadata = React.useMemo(function()
		if not allVersions or not selectedVersion then
			return nil
		end
		for _, v in allVersions do
			if v.package.version == selectedVersion then
				return v
			end
		end
		return allVersions[#allVersions]
	end, { allVersions, selectedVersion })

	-- Pull a casing hint from the upstream repository URL when available,
	-- so packages like `goodsignal` render as `GoodSignal` in PascalCase
	-- mode without us having to guess word boundaries.
	local repoHint: string? = nil
	if metadata and metadata.package and metadata.package.repository then
		local repo = metadata.package.repository
		local lastSegment = string.match(repo, "([^/]+)/?$")
		if lastSegment then
			lastSegment = (string.gsub(lastSegment, "%.git$", ""))
			repoHint = lastSegment
		end
	end
	local name = SettingsModule.formatPackageName(rawName, ctx.settings.namingConvention, {
		hint = repoHint,
		scope = scope,
		overrides = ctx.settings.nameOverrides,
	})

	local isLatestSelected = allVersions ~= nil
		and allVersions[1] ~= nil
		and allVersions[1].package.version == selectedVersion

	local installStatus, setInstallStatus = React.useState("idle")
	local installError: string?, setInstallError = React.useState(nil :: string?)
	local installProgress: string?, setInstallProgress = React.useState(nil :: string?)

	local installedMap = useAtom(InstalledState.map)
	local installedEntry = installedMap[`{scope}/{rawName}`]

	local dependents = React.useMemo(function()
		return InstalledPackages.findDependents(scope, rawName)
	end, { installedMap, scope, rawName } :: { any })

	React.useEffect(function()
		setInstallStatus("idle")
		setInstallError(nil)
		return nil
	end, { selectedVersion })

	local onBack = React.useCallback(function()
		nav.pop()
	end, { nav })

	local wallyWaitMessage = useWallyStatusMessage()

	local content
	if isLoading then
		content = e(View, {
			Size = UDim2.fromScale(1, 1),
			tag = "align-x-center align-y-center",
		}, {
			Layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 8),
			}),
			Loader = e(Loading, { size = IconSize.Large, LayoutOrder = 1 }),
			WaitMessage = if wallyWaitMessage
				then e(Text, {
					Text = wallyWaitMessage,
					AutomaticSize = Enum.AutomaticSize.XY,
					tag = "text-caption-small",
					LayoutOrder = 2,
				})
				else nil,
		})
	elseif metadata then
		local pkg = metadata.package
		local version = pkg.version or "?"
		local description = pkg.description or ""
		local license = pkg.license or "Unknown"
		local installRealm = pkg.realm or "shared"
		local alreadyInstalled = installedEntry ~= nil and installedEntry.version == selectedVersion
		local authors = pkg.authors
		local authorStr = if authors and #authors > 0 then table.concat(authors, ", ") else scope
		local repository = pkg.repository
		local homepage = pkg.homepage

		if description == "" then
			description = `{name} has no provided description.`
		end

		local allDeps = {}
		local function collectDeps(source, category)
			if source then
				for depName, depVersion in source do
					table.insert(allDeps, { name = depName, version = depVersion, category = category })
				end
			end
		end
		collectDeps(metadata.dependencies, "dependency")
		collectDeps(metadata["server-dependencies"], "server")
		collectDeps(metadata["dev-dependencies"], "dev")

		-- Group deps by category
		local depGroups: { [string]: { any } } = { dependency = {}, server = {}, dev = {} }
		for _, dep in allDeps do
			table.insert(depGroups[dep.category], dep)
		end

		local function onDepSelect(depScope: string, depName: string)
			nav.push("Package", { scope = depScope, name = depName })
		end

		local function buildDepGroup(category: string, label: string?, layoutOrder: number)
			local list = depGroups[category]
			if #list == 0 then
				return nil
			end
			return e(DependencyGroup, {
				label = label,
				deps = list,
				onSelect = onDepSelect,
				LayoutOrder = layoutOrder,
			})
		end

		local installAlias = SettingsModule.formatPackageName(rawName, ctx.settings.namingConvention, {
			hint = repoHint,
			scope = scope,
			overrides = ctx.settings.nameOverrides,
		})

		local function runInstall()
			setInstallStatus("installing")
			setInstallError(nil)
			setInstallProgress("Starting install...")

			task.spawn(function()
				local success, err, failures = Installer.install(
					scope,
					rawName,
					version,
					installAlias,
					installRealm,
					function(msg)
						setInstallProgress(msg)
					end,
					ctx.settings.skipTests
				)
				setInstallProgress(nil)

				if success then
					InstalledState.refresh()
					if failures and #failures > 0 then
						setInstallStatus("partial")
						setInstallError(
							`Installed, but {#failures} dependency issue(s):\n• ` .. table.concat(failures, "\n• ")
						)
					else
						setInstallStatus("installed")
						setInstallError(nil)
					end
				else
					setInstallStatus("error")
					setInstallError(err)
					warn("[Discover] Install failed:", err)
				end
			end)
		end

		local installButtonText = if installStatus == "installing"
			then "Installing..."
			elseif installStatus == "installed" or alreadyInstalled then "Installed"
			elseif installStatus == "partial" then "Installed (with warnings)"
			elseif installStatus == "error" then "Retry"
			else "Install"
		local installButtonDisabled = installStatus == "installing"
			or installStatus == "installed"
			or installStatus == "partial"
			or alreadyInstalled

		local nextPageOrder = ReactHelpers.createNextOrder()

		-- Header card: title, installed chip, author, description
		local headerChildren: { [string]: any } = {
			Padding = e("UIPadding", {
				PaddingLeft = UDim.new(0, 16),
				PaddingRight = UDim.new(0, 16),
				PaddingTop = UDim.new(0, 16),
				PaddingBottom = UDim.new(0, 16),
			}),
			Layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8),
			}),
			TitleRow = e("Frame", {
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = 1,
			}, {
				Layout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 8),
				}),
				Title = e(Text, {
					Text = `{scope}/{rawName}`,
					AutomaticSize = Enum.AutomaticSize.Y,
					Size = UDim2.fromScale(1, 0),
					TextWrapped = true,
					tag = "text-title-medium content-emphasis text-align-x-left",
					LayoutOrder = 1,
				}, {
					Flex = e("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }),
				}),
				InstalledChip = if installedEntry
					then e(Pill, {
						text = `Installed v{installedEntry.version}`,
						LayoutOrder = 2,
						emphasis = true,
					})
					else nil,
			}),
			Author = e(Text, {
				Text = `by {authorStr}`,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.fromScale(1, 0),
				tag = "text-caption-small content-muted text-align-x-left",
				LayoutOrder = 2,
			}),
			Description = e(Text, {
				Text = description,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.fromScale(1, 0),
				TextWrapped = true,
				tag = "text-body-small content-default text-align-x-left text-wrap",
				LayoutOrder = 3,
			}),
		}

		-- Pills row (facts)
		local factPillOrder = 0
		local function nextFactOrder()
			factPillOrder += 1
			return factPillOrder
		end
		local factsChildren: { [string]: any } = {
			Layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 6),
				Wraps = true,
			}),
			Realm = e(Pill, { text = installRealm, LayoutOrder = nextFactOrder() }),
			License = e(Pill, { text = license, LayoutOrder = nextFactOrder() }),
		}
		if allVersions then
			factsChildren.VersionCount = e(Pill, {
				text = `{#allVersions} versions`,
				LayoutOrder = nextFactOrder(),
			})
		end

		-- Action row: version dropdown + install button
		local versionItems = {}
		if allVersions then
			for i, versionData in allVersions do
				local v = versionData.package.version
				table.insert(versionItems, {
					id = v,
					text = i == 1 and `v{v} (latest)` or `v{v}`,
				})
			end
		end

		local linksChildren: { [string]: any } = {
			Layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 4),
			}),
		}
		local linkOrder = 0
		local function nextLinkOrder()
			linkOrder += 1
			return linkOrder
		end
		linksChildren.Wally = e(LinkRow, {
			label = "Wally",
			value = `https://wally.run/package/{scope}/{rawName}`,
			LayoutOrder = nextLinkOrder(),
		})
		if repository and repository ~= "" then
			linksChildren.Repository =
				e(LinkRow, { label = "Repository", value = repository, LayoutOrder = nextLinkOrder() })
		end
		if homepage and homepage ~= "" then
			linksChildren.Homepage = e(LinkRow, { label = "Homepage", value = homepage, LayoutOrder = nextLinkOrder() })
		end

		local snippetText = `{installAlias} = "{scope}/{rawName}@{version}"`

		local dependentsChildren: { [string]: any } = {
			Layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 2),
			}),
		}
		local dependentKey = ReactHelpers.createUniqueKey()
		local nextDependentOrder = ReactHelpers.createNextOrder()
		for _, dep in dependents do
			local depScope = dep.scope
			local depName = dep.name
			dependentsChildren[dependentKey(`{depScope}/{depName}`)] = e(Button, {
				text = `{depScope}/{depName}`,
				variant = ButtonVariant.Link,
				size = InputSize.Small,
				LayoutOrder = nextDependentOrder(),
				onActivated = function()
					nav.push("Package", { scope = depScope, name = depName })
				end,
			})
		end

		content = e(ScrollView, {
			Size = UDim2.fromScale(1, 1),
			scroll = {
				scrollBarVisibility = Visibility.Auto,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2.new(),
			},
		}, {
			ScrollLayout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 16),
			}),
			ScrollPadding = e("UIPadding", {
				PaddingLeft = UDim.new(0, 16),
				PaddingRight = UDim.new(0, 16),
				PaddingTop = UDim.new(0, 16),
				PaddingBottom = UDim.new(0, 16),
			}),

			Header = e(View, {
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = nextPageOrder(),
				tag = "bg-surface-100 radius-medium",
			}, headerChildren),

			ActionRow = e("Frame", {
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = nextPageOrder(),
			}, {
				Layout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 8),
				}),
				VersionWrap = e("Frame", {
					Size = UDim2.new(1, 0, 0, 40),
					BackgroundTransparency = 1,
					LayoutOrder = 1,
				}, {
					Flex = e("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }),
					Dropdown = e(Dropdown.Root, {
						label = "",
						value = selectedVersion,
						size = InputSize.Medium,
						width = UDim.new(1, 0),
						onItemChanged = function(id: string)
							setSelectedVersion(id)
						end,
						items = versionItems,
					}),
				}),
				Install = e(Button, {
					text = installButtonText,
					variant = if installStatus == "installed"
							or installStatus == "partial"
							or alreadyInstalled
						then ButtonVariant.Standard
						else ButtonVariant.Emphasis,
					size = InputSize.Medium,
					isDisabled = installButtonDisabled,
					onActivated = runInstall,
					LayoutOrder = 2,
				}),
			}),

			InstallHint = e(Text, {
				Text = `Will install as {installAlias}`,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.fromScale(1, 0),
				tag = "text-caption-small content-muted text-align-x-left",
				LayoutOrder = nextPageOrder(),
			}),

			OlderVersionBanner = if not isLatestSelected
					and installStatus == "idle"
					and not alreadyInstalled
				then e(SystemBanner, {
					severity = AlertSeverity.Warning,
					title = "Installing an older version",
					description = "The latest version is available in the dropdown above.",
					LayoutOrder = nextPageOrder(),
				})
				else nil,

			InstallProgress = if installProgress
				then e(Text, {
					Text = installProgress,
					AutomaticSize = Enum.AutomaticSize.Y,
					Size = UDim2.fromScale(1, 0),
					TextWrapped = true,
					tag = "text-caption-small content-muted text-align-x-left",
					LayoutOrder = nextPageOrder(),
				})
				else nil,

			InstallMessage = installError and e(SystemBanner, {
				severity = if installStatus == "partial" then AlertSeverity.Warning else AlertSeverity.Error,
				title = if installStatus == "partial" then "Installed with warnings" else "Install failed",
				description = installError,
				LayoutOrder = nextPageOrder(),
			}) or nil,

			Facts = e("Frame", {
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = nextPageOrder(),
			}, factsChildren),

			Snippet = e(View, {
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = nextPageOrder(),
				tag = "bg-surface-200 radius-small",
			}, {
				Padding = e("UIPadding", {
					PaddingLeft = UDim.new(0, 16),
					PaddingRight = UDim.new(0, 16),
					PaddingTop = UDim.new(0, 16),
					PaddingBottom = UDim.new(0, 16),
				}),
				Layout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 4),
				}),
				Label = e(Text, {
					Text = "wally.toml",
					AutomaticSize = Enum.AutomaticSize.Y,
					Size = UDim2.fromScale(1, 0),
					tag = "text-caption-small content-muted text-align-x-left",
					LayoutOrder = 1,
				}),
				Code = e(SelectableText, {
					text = snippetText,
					emphasis = true,
					LayoutOrder = 2,
				}),
			}),

			LinksSection = e("Frame", {
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = nextPageOrder(),
			}, {
				Layout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 8),
				}),
				Header = e(SectionHeader, { text = "Links", LayoutOrder = 1 }),
				List = e("Frame", {
					Size = UDim2.fromScale(1, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					LayoutOrder = 2,
				}, linksChildren),
			}),

			UsedBySection = e("Frame", {
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = nextPageOrder(),
			}, {
				Layout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 8),
				}),
				Header = e(SectionHeader, {
					text = #dependents > 0 and `Used by ({#dependents})` or "Used by",
					LayoutOrder = 1,
				}),
				List = if #dependents > 0
					then e("Frame", {
						Size = UDim2.fromScale(1, 0),
						AutomaticSize = Enum.AutomaticSize.Y,
						BackgroundTransparency = 1,
						LayoutOrder = 2,
					}, dependentsChildren)
					else e(Text, {
						Text = "Nothing installed depends on this yet.",
						AutomaticSize = Enum.AutomaticSize.Y,
						Size = UDim2.fromScale(1, 0),
						tag = "text-caption-small content-muted text-align-x-left",
						LayoutOrder = 2,
					}),
			}),

			DepsSection = e("Frame", {
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = nextPageOrder(),
			}, {
				Layout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 8),
				}),
				Header = e(SectionHeader, {
					text = #allDeps > 0 and `Dependencies ({#allDeps})` or "No dependencies",
					LayoutOrder = 1,
				}),
				Runtime = buildDepGroup("dependency", nil, 2),
				Server = buildDepGroup("server", "Server", 3),
				Dev = buildDepGroup("dev", "Dev", 4),
			}),
		})
	else
		content = e(View, {
			Size = UDim2.fromScale(1, 1),
			tag = "align-x-center align-y-center",
		}, {
			Error = e(Text, {
				Text = "Failed to load package info",
				tag = "text-label-medium",
			}),
		})
	end

	return e(React.Fragment, nil, {
		TopBar = e(View, {
			Size = UDim2.new(1, 0, 0, 56),
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
				PaddingTop = UDim.new(0, 8),
				PaddingBottom = UDim.new(0, 8),
			}),
			Back = e(IconButton, {
				icon = Foundation.Enums.IconName.ChevronLargeLeft,
				size = InputSize.Medium,
				variant = ButtonVariant.Standard,
				onActivated = onBack,
				LayoutOrder = 1,
			}),
			Title = e(Text, {
				Text = name,
				AutomaticSize = Enum.AutomaticSize.XY,
				tag = "text-label-medium content-emphasis text-truncate-end",
				LayoutOrder = 2,
			}),
		}),

		TopDivider = e(Divider, {
			LayoutOrder = 2,
		}),

		Content = e("Frame", {
			Size = UDim2.new(1, 0, 1, -58),
			BackgroundTransparency = 1,
			LayoutOrder = 3,
		}, {
			Inner = content,
		}),
	})
end

return Package
