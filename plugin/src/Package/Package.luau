local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Foundation = require(Packages.Foundation)
local React = require(Packages.React)

local DependencyGroup = require(script.Parent.DependencyGroup)
local InstalledPackages = require(Discover.Src.WallyInstall.InstalledPackages)
local InstalledState = require(Discover.Src.InstalledStore)
local LinkRow = require(Discover.Src.Common.LinkRow)
local Navigation = require(Discover.Src.Navigation)
local PackageActions = require(script.Parent.PackageActions)
local PackageHeader = require(script.Parent.PackageHeader)
local Pill = require(Discover.Src.Common.Pill)
local ReactHelpers = require(Discover.Src.Common.React)
local Section = require(Discover.Src.Common.Section)
local SettingsModule = require(Discover.Src.Settings.SettingsStore)
local WallyAPI = require(Discover.Src.Api.Wally)
local useAtom = require(Discover.Src.Common.useAtom)
local useInstaller = require(script.Parent.useInstaller)
local useWallyStatusMessage = require(Discover.Src.Api.useWallyStatus)

local View = Foundation.View
local Text = Foundation.Text
local Button = Foundation.Button
local IconButton = Foundation.IconButton
local Divider = Foundation.Divider
local ScrollView = Foundation.ScrollView
local Loading = Foundation.Loading

local InputSize = Foundation.Enums.InputSize
local ButtonVariant = Foundation.Enums.ButtonVariant
local IconSize = Foundation.Enums.IconSize
local Visibility = Foundation.Enums.Visibility

local e = React.createElement

local function Package()
	local nav = Navigation.useNavigation()
	local screen = nav.screen
	local scope = screen.options and screen.options.scope or ""
	local rawName = screen.options and screen.options.name or ""
	local requestedVersion: string? = screen.options and screen.options.version
	local settingsContext = SettingsModule.useSettings()

	local allVersions: { any }?, setAllVersions = React.useState(nil :: { any }?)
	local selectedVersion: string?, setSelectedVersion = React.useState(nil :: string?)
	local isLoading, setIsLoading = React.useState(true)

	React.useEffect(function()
		if scope == "" or rawName == "" then
			setIsLoading(false)
			return
		end

		local cancelled = false
		setIsLoading(true)
		task.spawn(function()
			local data = WallyAPI.metadataAsync(scope, rawName)
			if cancelled then
				return
			end
			if data and data.versions and #data.versions > 0 then
				setAllVersions(data.versions)
				local initialVersion = data.versions[1].package.version
				if requestedVersion then
					for _, version in data.versions do
						if version.package.version == requestedVersion then
							initialVersion = requestedVersion
							break
						end
					end
				end
				setSelectedVersion(initialVersion)
			end
			setIsLoading(false)
		end)
		return function()
			cancelled = true
		end
	end, { scope, rawName, requestedVersion } :: { any })

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

	local repositoryHint: string? = nil
	if metadata and metadata.package and metadata.package.repository then
		local repo = metadata.package.repository
		local lastSegment = string.match(repo, "([^/]+)/?$")
		if lastSegment then
			lastSegment = (string.gsub(lastSegment, "%.git$", ""))
			repositoryHint = lastSegment
		end
	end
	local name = SettingsModule.formatPackageName(rawName, settingsContext.settings.namingConvention, {
		hint = repositoryHint,
		overrides = settingsContext.settings.nameOverrides,
	})

	local isLatestSelected = allVersions ~= nil
		and allVersions[1] ~= nil
		and allVersions[1].package.version == selectedVersion

	local installedMap = useAtom(InstalledState.map)
	local installedEntry = installedMap[`{scope}/{rawName}`]

	local packageData = metadata and metadata.package
	local version = if packageData then packageData.version or "?" else "?"
	local installRealm = if packageData then packageData.realm or "shared" else "shared"
	local alreadyInstalled = installedEntry ~= nil and installedEntry.version == selectedVersion

	local installAlias = SettingsModule.formatPackageName(rawName, settingsContext.settings.namingConvention, {
		hint = repositoryHint,
		overrides = settingsContext.settings.nameOverrides,
	})

	local installer = useInstaller(
		scope,
		rawName,
		version,
		installAlias,
		installRealm,
		settingsContext.settings.verboseLogging,
		selectedVersion
	)

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
		local description = packageData.description or ""
		local license = packageData.license or "Unknown"
		local authors = packageData.authors
		local repository = packageData.repository
		local homepage = packageData.homepage

		if description == "" then
			description = `{name} has no provided description.`
		end

		local allDependencies = {}
		local function collectDeps(source, category)
			if source then
				for dependencyName, dependencyVersion in source do
					table.insert(
						allDependencies,
						{ name = dependencyName, version = dependencyVersion, category = category }
					)
				end
			end
		end
		collectDeps(metadata.dependencies, "dependency")
		collectDeps(metadata["server-dependencies"], "server")
		collectDeps(metadata["dev-dependencies"], "dev")

		local dependencyGroups: { [string]: { any } } = { dependency = {}, server = {}, dev = {} }
		for _, dep in allDependencies do
			table.insert(dependencyGroups[dep.category], dep)
		end

		local function onDependencySelect(dependencyScope: string, dependencyName: string, dependencyVersion: string?)
			nav.push("Package", {
				scope = dependencyScope,
				name = dependencyName,
				version = dependencyVersion,
			})
		end

		local function buildDepGroup(category: string, layoutOrder: number)
			local list = dependencyGroups[category]
			if #list == 0 then
				return nil
			end
			return e(DependencyGroup, {
				deps = list,
				onSelect = onDependencySelect,
				LayoutOrder = layoutOrder,
			})
		end

		local dependents = InstalledPackages.findDependents(scope, rawName)

		local nextFactOrder = ReactHelpers.createNextOrder()
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
			local dependencyScope = dep.scope
			local dependencyName = dep.name
			dependentsChildren[dependentKey(`{dependencyScope}/{dependencyName}`)] = e(Button, {
				text = `{dependencyScope}/{dependencyName}`,
				variant = ButtonVariant.Link,
				size = InputSize.Small,
				LayoutOrder = nextDependentOrder(),
				onActivated = function()
					nav.push("Package", { scope = dependencyScope, name = dependencyName })
				end,
			})
		end

		local nextPageOrder = ReactHelpers.createNextOrder()

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

			Header = e(PackageHeader, {
				scope = scope,
				name = rawName,
				description = description,
				authors = authors,
				authorFallback = scope,
				installedVersion = if installedEntry then installedEntry.version else nil,
				LayoutOrder = nextPageOrder(),
			}),

			Actions = e(PackageActions, {
				selectedVersion = selectedVersion,
				versionItems = versionItems,
				onVersionChanged = setSelectedVersion,
				installStatus = installer.status,
				installError = installer.error,
				installProgress = installer.progress,
				isDevRealm = installRealm == "dev",
				isLatestSelected = isLatestSelected,
				alreadyInstalled = alreadyInstalled,
				onInstall = installer.run,
				LayoutOrder = nextPageOrder(),
			}),

			Facts = e("Frame", {
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = nextPageOrder(),
			}, factsChildren),

			LinksSection = e(Section, {
				text = "Links",
				LayoutOrder = nextPageOrder(),
			}, linksChildren),

			UsedBySection = e(Section, {
				text = #dependents > 0 and `Used by ({#dependents})` or "Used by",
				LayoutOrder = nextPageOrder(),
			}, {
				List = if #dependents > 0
					then e("Frame", {
						Size = UDim2.fromScale(1, 0),
						AutomaticSize = Enum.AutomaticSize.Y,
						BackgroundTransparency = 1,
					}, dependentsChildren)
					else e(Text, {
						Text = "Nothing installed depends on this yet.",
						AutomaticSize = Enum.AutomaticSize.Y,
						Size = UDim2.fromScale(1, 0),
						tag = "text-caption-small content-muted text-align-x-left",
					}),
			}),

			SharedDeps = #dependencyGroups.dependency > 0 and e(Section, {
				text = `Shared Dependencies ({#dependencyGroups.dependency})`,
				LayoutOrder = nextPageOrder(),
			}, {
				Group = buildDepGroup("dependency", 1),
			}),

			ServerDeps = #dependencyGroups.server > 0 and e(Section, {
				text = `Server Dependencies ({#dependencyGroups.server})`,
				LayoutOrder = nextPageOrder(),
			}, {
				Group = buildDepGroup("server", 1),
			}),

			DevDeps = #dependencyGroups.dev > 0 and e(Section, {
				text = `Dev Dependencies ({#dependencyGroups.dev})`,
				LayoutOrder = nextPageOrder(),
			}, {
				Group = buildDepGroup("dev", 1),
			}),

			NoDeps = #allDependencies == 0 and e(Section, {
				text = "No dependencies",
				collapsible = false,
				LayoutOrder = nextPageOrder(),
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
