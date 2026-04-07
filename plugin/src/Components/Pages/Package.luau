local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local React = require(Packages.React)
local Foundation = require(Packages.Foundation)

local Navigation = require(Discover.Src.Navigation)
local SettingsModule = require(Discover.Src.Settings)
local WallyAPI = require(Discover.Src.Utility.WallyAPI)
local Installer = require(Discover.Src.Utility.Installer)

local View = Foundation.View
local Text = Foundation.Text
local Button = Foundation.Button
local IconButton = Foundation.IconButton
local Divider = Foundation.Divider
local ScrollView = Foundation.ScrollView
local Loading = Foundation.Loading
local FeedbackAlert = Foundation.FeedbackAlert

local InputSize = Foundation.Enums.InputSize
local ButtonVariant = Foundation.Enums.ButtonVariant
local IconSize = Foundation.Enums.IconSize
local Visibility = Foundation.Enums.Visibility
local AlertSeverity = Foundation.Enums.AlertSeverity

local e = React.createElement

local function MetadataRow(props: { label: string, value: string, LayoutOrder: number })
	return e("Frame", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
	}, {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 6),
		}),
		Label = e(Text, {
			Text = props.label,
			AutomaticSize = Enum.AutomaticSize.XY,
			tag = "text-caption-small",
			LayoutOrder = 1,
		}),
		Value = e(Text, {
			Text = props.value,
			AutomaticSize = Enum.AutomaticSize.XY,
			tag = "text-caption-small content-emphasis",
			LayoutOrder = 2,
		}),
	})
end

local function Package()
	local nav = Navigation.useNavigation()
	local screen = nav.screen
	local scope = screen.options and screen.options.scope or ""
	local rawName = screen.options and screen.options.name or ""
	local ctx = SettingsModule.useSettings()
	local name = SettingsModule.formatPackageName(rawName, ctx.settings.namingConvention)

	local allVersions, setAllVersions = React.useState(nil :: { any }?)
	local selectedVersion, setSelectedVersion = React.useState(nil :: string?)
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

	local installStatus, setInstallStatus = React.useState("idle")
	local installError, setInstallError = React.useState(nil :: string?)

	React.useEffect(function()
		setInstallStatus("idle")
		setInstallError(nil)
		return nil
	end, { selectedVersion })

	local onBack = React.useCallback(function()
		nav.pop()
	end, { nav })

	local content
	if isLoading then
		content = e(View, {
			Size = UDim2.fromScale(1, 1),
			tag = "align-x-center align-y-center",
		}, {
			Loader = e(Loading, { size = IconSize.Large }),
		})
	elseif metadata then
		local pkg = metadata.package
		local version = pkg.version or "?"
		local description = pkg.description or ""
		local license = pkg.license or "Unknown"
		local installRealm = pkg.realm or "shared"
		local authors = pkg.authors
		local authorStr = authors and table.concat(authors, ", ") or "Unknown"

		if description == "" then
			description = `{rawName} has no provided description.`
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

		local function parseDepPath(depVersion: string): (string?, string?)
			local path = string.match(depVersion, "^([^@]+)")
			if path then
				local s, n = string.match(path, "^(.+)/(.+)$")
				return s, n
			end
			return nil, nil
		end

		local depChildren = {}
		depChildren.Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 2),
		})
		for i, dep in allDeps do
			local depScope, depName = parseDepPath(tostring(dep.version))
			local suffix = ""
			if dep.category == "dev" then
				suffix = "  (dev)"
			elseif dep.category == "server" then
				suffix = "  (server)"
			end
			local displayName = depScope and `{depScope}/{depName}` or dep.name

			depChildren["dep_" .. i] = e(Button, {
				text = displayName .. suffix,
				variant = ButtonVariant.Link,
				size = InputSize.Small,
				LayoutOrder = i,
				onActivated = depScope and function()
					nav.push("Package", { scope = depScope, name = depName })
				end or nil,
			})
		end

		content = e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
		}, {
			ContentLayout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			FixedHeader = e("Frame", {
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = 1,
			}, {
				HeaderLayout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 10),
				}),
				HeaderPadding = e("UIPadding", {
					PaddingLeft = UDim.new(0, 16),
					PaddingRight = UDim.new(0, 16),
					PaddingTop = UDim.new(0, 16),
					PaddingBottom = UDim.new(0, 8),
				}),

				Title = e(Text, {
					Text = `{scope}/{rawName}`,
					AutomaticSize = Enum.AutomaticSize.XY,
					tag = "text-title-medium content-emphasis",
					LayoutOrder = 1,
				}),

				Description = e(Text, {
					Text = description,
					AutomaticSize = Enum.AutomaticSize.Y,
					Size = UDim2.fromScale(1, 0),
					tag = "text-label-small text-align-x-left",
					LayoutOrder = 2,
				}),

				VersionLabel = e(Text, {
					Text = "Version",
					AutomaticSize = Enum.AutomaticSize.XY,
					tag = "text-label-small content-emphasis",
					LayoutOrder = 3,
				}),
				VersionList = e("Frame", {
					Size = UDim2.fromScale(1, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					LayoutOrder = 4,
				}, {
					Layout = e("UIListLayout", {
						FillDirection = Enum.FillDirection.Horizontal,
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 6),
						Wraps = true,
					}),
					VersionButtons = e(
						React.Fragment,
						nil,
						(function()
							local buttons = {}
							if allVersions then
								for i, versionData in allVersions do
									local v = versionData.package.version
									local isSelected = v == selectedVersion
									buttons["v_" .. v] = e("TextButton", {
										Text = i == 1 and `v{v} (latest)` or `v{v}`,
										Size = UDim2.fromOffset(0, 28),
										AutomaticSize = Enum.AutomaticSize.X,
										BackgroundColor3 = if isSelected
											then Color3.fromRGB(60, 120, 255)
											else Color3.fromRGB(40, 42, 48),
										TextColor3 = Color3.fromRGB(247, 247, 248),
										FontFace = Font.fromEnum(Enum.Font.GothamMedium),
										TextSize = 13,
										LayoutOrder = i,
										[React.Event.Activated] = function()
											setSelectedVersion(v)
										end,
									}, {
										Corner = e("UICorner", { CornerRadius = UDim.new(0, 6) }),
										Padding = e("UIPadding", {
											PaddingLeft = UDim.new(0, 10),
											PaddingRight = UDim.new(0, 10),
										}),
									})
								end
							end
							return buttons
						end)()
					),
				}),
			}),

			InstallRow = e("Frame", {
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = 2,
			}, {
				InstallPadding = e("UIPadding", {
					PaddingLeft = UDim.new(0, 16),
					PaddingRight = UDim.new(0, 16),
					PaddingTop = UDim.new(0, 4),
					PaddingBottom = UDim.new(0, 8),
				}),
				InstallLayout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 6),
				}),
				InstallMessage = installError and e(FeedbackAlert, {
					severity = if installStatus == "partial" then AlertSeverity.Warning else AlertSeverity.Error,
					title = if installStatus == "partial" then "Installed with warnings" else "Install failed",
					description = installError,
					LayoutOrder = 2,
				}) or nil,
				Install = e(Button, {
					LayoutOrder = 1,
					text = if installStatus == "installing"
							then "Installing..."
						elseif installStatus == "installed" then "Installed"
						elseif installStatus == "partial" then "Installed (with warnings)"
						elseif installStatus == "error" then "Error"
						else "Install",
					variant = if installStatus == "installed" or installStatus == "partial"
						then ButtonVariant.Standard
						else ButtonVariant.Emphasis,
					size = InputSize.Medium,
					isDisabled = installStatus == "installing"
						or installStatus == "installed"
						or installStatus == "partial",
					onActivated = function()
						setInstallStatus("installing")
						setInstallError(nil)

						task.spawn(function()
							local alias = SettingsModule.formatPackageName(rawName, ctx.settings.namingConvention)
							local success, err, failures = Installer.install(scope, rawName, version, alias, installRealm)

							if success then
								if failures and #failures > 0 then
									setInstallStatus("partial")
									setInstallError(`Installed, but {#failures} dependency issue(s):\n• ` .. table.concat(failures, "\n• "))
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
					end,
				}),
			}),

			HeaderDivider = e(Divider, { LayoutOrder = 3 }),

			Details = e(ScrollView, {
				Size = UDim2.new(1, 0, 1, -200),
				LayoutOrder = 4,
				scroll = {
					scrollBarVisibility = Visibility.Auto,
					ScrollingDirection = Enum.ScrollingDirection.Y,
				},
			}, {
				ScrollLayout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 10),
				}),
				ScrollPadding = e("UIPadding", {
					PaddingLeft = UDim.new(0, 16),
					PaddingRight = UDim.new(0, 16),
					PaddingTop = UDim.new(0, 12),
					PaddingBottom = UDim.new(0, 16),
				}),

				MetaSection = e("Frame", {
					Size = UDim2.fromScale(1, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					LayoutOrder = 1,
				}, {
					Layout = e("UIListLayout", {
						FillDirection = Enum.FillDirection.Vertical,
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 6),
					}),
					Realm = e(MetadataRow, { label = "Realm", value = installRealm, LayoutOrder = 1 }),
					License = e(MetadataRow, { label = "License", value = license, LayoutOrder = 2 }),
					Authors = e(MetadataRow, { label = "Authors", value = authorStr, LayoutOrder = 3 }),
				}),

				DepDivider = e(Divider, { LayoutOrder = 2 }),

				DepHeader = e(Text, {
					Text = #allDeps > 0 and `Dependencies ({#allDeps})` or "No dependencies",
					AutomaticSize = Enum.AutomaticSize.XY,
					tag = "text-label-small content-emphasis",
					LayoutOrder = 3,
				}),

				DepList = #allDeps > 0 and e("Frame", {
					Size = UDim2.fromScale(1, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					LayoutOrder = 4,
				}, depChildren) or nil,
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
			Size = UDim2.new(1, 0, 1, -50),
			BackgroundTransparency = 1,
			LayoutOrder = 3,
		}, {
			Inner = content,
		}),
	})
end

return Package
