local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Foundation = require(Packages.Foundation)
local React = require(Packages.React)

local InstalledRow = require(script.InstalledRow)
local InstalledState = require(Discover.Src.Installer.InstalledStore)
local Installer = require(Discover.Src.Installer.Installer)
local Navigation = require(Discover.Src.Navigation)
local ReactHelpers = require(Discover.Src.Common.React)
local SettingsModule = require(Discover.Src.Settings)
local WallyAPI = require(Discover.Src.Wally.Api)
local useAtom = require(Discover.Src.Common.useAtom)

local View = Foundation.View
local Text = Foundation.Text
local Checkbox = Foundation.Checkbox
local IconButton = Foundation.IconButton
local Divider = Foundation.Divider
local ScrollView = Foundation.ScrollView
local Dialog = Foundation.Dialog
local Empty = Foundation.Empty

local InputSize = Foundation.Enums.InputSize
local ButtonVariant = Foundation.Enums.ButtonVariant
local Visibility = Foundation.Enums.Visibility

local e = React.createElement

local function Manage()
	local nav = Navigation.useNavigation()
	local settingsCtx = SettingsModule.useSettings()
	local installed = useAtom(InstalledState.list)
	local latestVersions, setLatestVersions = React.useState({} :: { [string]: string })
	local pendingUninstall: { scope: string, name: string }?, setPendingUninstall =
		React.useState(nil :: { scope: string, name: string }?)

	local settingsRef = React.useRef(settingsCtx)
	settingsRef.current = settingsCtx

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

	local onRowSelect = React.useCallback(function(scope: string, name: string)
		nav.push("Package", { scope = scope, name = name })
	end, { nav })

	local onRowUpdate = React.useCallback(function(scope: string, name: string)
		local target = latestVersions[`{scope}/{name}`]
		if not target then
			return
		end
		local pkg
		for _, candidate in installed do
			if candidate.scope == scope and candidate.name == name then
				pkg = candidate
				break
			end
		end
		if not pkg then
			return
		end
		task.spawn(function()
			local ctx = settingsRef.current
			local alias = SettingsModule.formatPackageName(name, ctx.settings.namingConvention, {
				overrides = ctx.settings.nameOverrides,
			})
			local ok, err = Installer.install(scope, name, target, alias, pkg.realm)
			if not ok then
				warn("[Discover] Update failed:", err)
			end
			InstalledState.refresh()
		end)
	end, { installed, latestVersions } :: { any })

	local onRowUninstall = React.useCallback(function(scope: string, name: string)
		if settingsCtx.settings.skipUninstallConfirm then
			local ok, err = Installer.uninstall(scope, name)
			if not ok then
				warn("[Discover] Uninstall failed:", err)
			end
			InstalledState.refresh()
		else
			setPendingUninstall({ scope = scope, name = name })
		end
	end, { settingsCtx })

	local rows: { [string]: any } = {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}
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
			onSelect = onRowSelect,
			onUpdate = onRowUpdate,
			onUninstall = onRowUninstall,
		})
		rows[rowKey(`divider_{key}`)] = e(Divider, { LayoutOrder = nextRowOrder() })
	end

	local content
	if #installed == 0 then
		content = e(Empty, {
			icon = { name = "icons/common/search" },
			text = "No packages installed",
		})
	else
		local installedCount = #installed .. " installed"
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
					Text = installedCount,
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
				}, rows),
			}),
		})
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
					Layout = e("UIListLayout", {
						FillDirection = Enum.FillDirection.Vertical,
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 12),
					}),
					Body = e(Dialog.Text, {
						Text = `This will remove {pendingUninstall.scope}/{pendingUninstall.name} and any dependencies that are no longer needed.`,
						LayoutOrder = 1,
					}),
					DoNotAsk = e(Checkbox, {
						label = "Don't ask me again",
						isChecked = false,
						onActivated = function()
							settingsCtx.setSetting("skipUninstallConfirm", true)
						end,
						size = InputSize.Small,
						LayoutOrder = 2,
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
									local ok, err = Installer.uninstall(pendingUninstall.scope, pendingUninstall.name)
									if not ok then
										warn("[Discover] Uninstall failed:", err)
									end
								end
								setPendingUninstall(nil)
								InstalledState.refresh()
							end,
						},
					},
				}),
			})
			else nil,

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
				Text = "Installed",
				AutomaticSize = Enum.AutomaticSize.XY,
				tag = "text-label-medium content-emphasis",
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

return Manage
