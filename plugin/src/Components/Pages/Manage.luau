local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Foundation = require(Packages.Foundation)
local React = require(Packages.React)

local Navigation = require(Discover.Src.Navigation)
local Installer = require(Discover.Src.Utility.Installer)
local InstalledPackages = require(Discover.Src.Utility.InstalledPackages)

local View = Foundation.View
local Text = Foundation.Text
local Button = Foundation.Button
local IconButton = Foundation.IconButton
local Divider = Foundation.Divider
local ScrollView = Foundation.ScrollView

local InputSize = Foundation.Enums.InputSize
local ButtonVariant = Foundation.Enums.ButtonVariant
local Visibility = Foundation.Enums.Visibility

local e = React.createElement

local function InstalledRow(props: {
	scope: string,
	name: string,
	version: string,
	realm: string,
	onOpen: () -> (),
	onUninstall: () -> (),
	LayoutOrder: number,
})
	return e(View, {
		Size = UDim2.new(1, 0, 0, 56),
		LayoutOrder = props.LayoutOrder,
	}, {
		RowLayout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 8),
		}),
		Padding = e("UIPadding", {
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
		}),

		Info = e("Frame", {
			Size = UDim2.new(1, -160, 1, 0),
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
				Text = `v{props.version}  •  {props.realm}`,
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

		Uninstall = e(Button, {
			text = "Uninstall",
			variant = ButtonVariant.Utility,
			size = InputSize.Small,
			onActivated = props.onUninstall,
			LayoutOrder = 3,
		}),
	})
end

local function Manage()
	local nav = Navigation.useNavigation()
	local refreshKey, setRefreshKey = React.useState(0)

	local installed = React.useMemo(function()
		return InstalledPackages.list()
	end, { refreshKey })

	local onBack = React.useCallback(function()
		nav.pop()
	end, { nav })

	local rows = {}
	rows.Layout = e("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	for i, pkg in installed do
		local order = i * 2
		rows[`row_{pkg.scope}_{pkg.name}`] = e(InstalledRow, {
			scope = pkg.scope,
			name = pkg.name,
			version = pkg.version,
			realm = pkg.realm,
			LayoutOrder = order - 1,
			onOpen = function()
				nav.push("Package", { scope = pkg.scope, name = pkg.name })
			end,
			onUninstall = function()
				local ok, err = Installer.uninstall(pkg.scope, pkg.name)
				if not ok then
					warn("[Discover] Uninstall failed:", err)
				end
				setRefreshKey(function(k)
					return k + 1
				end)
			end,
		})
		rows[`divider_{i}`] = e(Divider, { LayoutOrder = order })
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
