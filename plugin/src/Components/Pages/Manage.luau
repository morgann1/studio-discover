local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Foundation = require(Packages.Foundation)
local React = require(Packages.React)

local Navigation = require(Discover.Src.Navigation)
local SettingsModule = require(Discover.Src.Settings)
local Installer = require(Discover.Src.Utility.Installer)
local InstalledPackages = require(Discover.Src.Utility.InstalledPackages)
local WallyAPI = require(Discover.Src.Utility.WallyAPI)
local ReactHelpers = require(Discover.Src.Utility.React)

local View = Foundation.View
local Text = Foundation.Text
local Button = Foundation.Button
local IconButton = Foundation.IconButton
local Divider = Foundation.Divider
local ScrollView = Foundation.ScrollView
local Dialog = Foundation.Dialog

local InputSize = Foundation.Enums.InputSize
local ButtonVariant = Foundation.Enums.ButtonVariant
local Visibility = Foundation.Enums.Visibility

local e = React.createElement

local function InstalledRow(props: {
	scope: string,
	name: string,
	version: string,
	realm: string,
	latestVersion: string?,
	onOpen: () -> (),
	onUpdate: (() -> ())?,
	onUninstall: () -> (),
	LayoutOrder: number,
})
	local updateAvailable = props.latestVersion ~= nil and props.latestVersion ~= props.version
	local metaText = `v{props.version}  •  {props.realm}`
	if updateAvailable then
		metaText ..= `  •  update to v{props.latestVersion}`
	end

	return e(View, {
		Size = UDim2.new(1, 0, 0, 56),
		LayoutOrder = props.LayoutOrder,
	}, {
		RowLayout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 6),
		}),
		Padding = e("UIPadding", {
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
		}),

		Info = e("Frame", {
			Size = UDim2.new(1, if updateAvailable then -220 else -160, 1, 0),
			BackgroundTransparency = 1,
			LayoutOrder = 1,
		}, {
			InfoLayout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 2),
			}),
			Title = e(Text, {
				Text = `{props.scope}/{props.name}`,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.fromScale(1, 0),
				tag = "text-label-medium content-emphasis text-truncate-end text-align-x-left",
				LayoutOrder = 1,
			}),
			Meta = e(Text, {
				Text = metaText,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.fromScale(1, 0),
				tag = "text-caption-small text-align-x-left",
				LayoutOrder = 2,
			}),
		}),

		Open = e(Button, {
			text = "Open",
			variant = ButtonVariant.Standard,
			size = InputSize.Small,
			onActivated = props.onOpen,
			LayoutOrder = 2,
		}),

		Update = if updateAvailable and props.onUpdate
			then e(Button, {
				text = "Update",
				variant = ButtonVariant.Emphasis,
				size = InputSize.Small,
				onActivated = props.onUpdate,
				LayoutOrder = 3,
			})
			else nil,

		Uninstall = e(Button, {
			text = "Uninstall",
			variant = ButtonVariant.Utility,
			size = InputSize.Small,
			onActivated = props.onUninstall,
			LayoutOrder = 4,
		}),
	})
end

local function Manage()
	local nav = Navigation.useNavigation()
	local settingsCtx = SettingsModule.useSettings()
	local refreshKey, setRefreshKey = React.useState(0)
	local latestVersions, setLatestVersions =
		React.useState({} :: { [string]: string })
	local pendingUninstall: { scope: string, name: string }?, setPendingUninstall =
		React.useState(nil :: { scope: string, name: string }?)

	local installed = React.useMemo(function()
		return InstalledPackages.list()
	end, { refreshKey })

	-- Fetch latest version for each installed package to detect updates
	React.useEffect(function()
		local cancelled = false
		for _, pkg in installed do
			task.spawn(function()
				local meta = WallyAPI.metadata(pkg.scope, pkg.name)
				if cancelled then
					return
				end
				if meta and meta.versions and meta.versions[1] and meta.versions[1].package then
					local latest = meta.versions[1].package.version
					setLatestVersions(function(prev)
						local new = table.clone(prev)
						new[`{pkg.scope}/{pkg.name}`] = latest
						return new
					end)
				end
			end)
		end
		return function()
			cancelled = true
		end
	end, { installed })

	local onBack = React.useCallback(function()
		nav.pop()
	end, { nav })

	local function refresh()
		setRefreshKey(function(k)
			return k + 1
		end)
	end

	local rows = {}
	rows.Layout = e("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	local rowKey = ReactHelpers.createUniqueKey()
	local nextRowOrder = ReactHelpers.createNextOrder()
	for _, pkg in installed do
		local key = `{pkg.scope}/{pkg.name}`
		local latest = latestVersions[key]
		rows[rowKey(key)] = e(InstalledRow, {
			scope = pkg.scope,
			name = pkg.name,
			version = pkg.version,
			realm = pkg.realm,
			latestVersion = latest,
			LayoutOrder = nextRowOrder(),
			onOpen = function()
				nav.push("Package", { scope = pkg.scope, name = pkg.name })
			end,
			onUpdate = if latest and latest ~= pkg.version
				then function()
					task.spawn(function()
						local alias =
							SettingsModule.formatPackageName(pkg.name, settingsCtx.settings.namingConvention)
						local ok, err = Installer.install(pkg.scope, pkg.name, latest, alias, pkg.realm)
						if not ok then
							warn("[Discover] Update failed:", err)
						end
						refresh()
					end)
				end
				else nil,
			onUninstall = function()
				setPendingUninstall({ scope = pkg.scope, name = pkg.name })
			end,
		})
		rows[rowKey(`divider_{key}`)] = e(Divider, { LayoutOrder = nextRowOrder() })
	end

	local content
	if #installed == 0 then
		content = e(View, {
			Size = UDim2.fromScale(1, 1),
			tag = "align-x-center align-y-center",
		}, {
			Empty = e(Text, {
				Text = "No packages installed",
				tag = "text-label-medium",
			}),
		})
	else
		content = e(ScrollView, {
			Size = UDim2.fromScale(1, 1),
			scroll = {
				scrollBarVisibility = Visibility.Auto,
				ScrollingDirection = Enum.ScrollingDirection.Y,
			},
		}, rows)
	end

	return e(React.Fragment, nil, {
		ConfirmDialog = if pendingUninstall
			then e(Dialog.Root, {
				disablePortal = false,
				hasBackdrop = true,
				onClose = function()
					setPendingUninstall(nil)
				end,
			}, {
				DialogTitle = e(Dialog.Title, { text = "Uninstall package?" }),
				DialogContent = e(Dialog.Content, nil, {
					Body = e(Dialog.Text, {
						Text = `This will remove {pendingUninstall.scope}/{pendingUninstall.name} and any dependencies that are no longer needed.`,
					}),
				}),
				DialogActions = e(Dialog.Actions, {
					actions = {
						{
							text = "Cancel",
							variant = ButtonVariant.Standard,
							onActivated = function()
								setPendingUninstall(nil)
							end,
						},
						{
							text = "Uninstall",
							variant = ButtonVariant.Emphasis,
							onActivated = function()
								if pendingUninstall then
									local ok, err =
										Installer.uninstall(pendingUninstall.scope, pendingUninstall.name)
									if not ok then
										warn("[Discover] Uninstall failed:", err)
									end
								end
								setPendingUninstall(nil)
								refresh()
							end,
						},
					},
				}),
			})
			else nil,

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
				Text = "Installed Packages",
				AutomaticSize = Enum.AutomaticSize.XY,
				tag = "text-label-medium content-emphasis",
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

return Manage
