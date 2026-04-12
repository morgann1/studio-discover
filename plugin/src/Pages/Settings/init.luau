local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Foundation = require(Packages.Foundation)
local React = require(Packages.React)

local Navigation = require(Discover.Src.Navigation)
local ReactHelpers = require(Discover.Src.Common.React)
local SettingRow = require(script.SettingRow)
local SettingsModule = require(Discover.Src.Settings)

local View = Foundation.View
local Text = Foundation.Text
local Checkbox = Foundation.Checkbox
local IconButton = Foundation.IconButton
local Divider = Foundation.Divider
local Dropdown = Foundation.Dropdown
local ScrollView = Foundation.ScrollView

local InputSize = Foundation.Enums.InputSize
local ButtonVariant = Foundation.Enums.ButtonVariant
local Visibility = Foundation.Enums.Visibility

local e = React.createElement

local CONVENTION_ITEMS = {
	{ id = "Normal", text = "Normal" },
	{ id = "PascalCase", text = "PascalCase" },
	{ id = "camelCase", text = "camelCase" },
	{ id = "snake_case", text = "snake_case" },
}

local PREVIEW_SAMPLE = "react-roblox"

local function Settings()
	local nav = Navigation.useNavigation()
	local ctx = SettingsModule.useSettings()
	local current = ctx.settings.namingConvention
	local previewText = SettingsModule.formatPackageName(PREVIEW_SAMPLE, current)

	local onBack = React.useCallback(function()
		nav.pop()
	end, { nav })

	local rows = {
		{
			key = "NamingConvention",
			name = "Naming Convention",
			description = "How package names are formatted when installed.",
			footer = e(Text, {
				Text = `Example: {PREVIEW_SAMPLE} → {previewText}`,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.fromScale(1, 0),
				tag = "text-caption-small content-muted text-align-x-left",
			}),
			control = e("Frame", {
				Size = UDim2.fromOffset(200, 40),
				BackgroundTransparency = 1,
			}, {
				Dropdown = e(Dropdown.Root, {
					label = "",
					size = InputSize.Medium,
					width = UDim.new(1, 0),
					value = current,
					items = CONVENTION_ITEMS,
					onItemChanged = function(id: string)
						ctx.setSetting("namingConvention", id)
					end,
				}),
			}),
		},
		{
			key = "CheckForUpdates",
			name = "Check for updates",
			description = "Show a banner when a new version of Discover is available on GitHub.",
			control = e(Checkbox, {
				isChecked = ctx.settings.checkForUpdates,
				onActivated = function()
					ctx.setSetting("checkForUpdates", not ctx.settings.checkForUpdates)
				end,
				size = InputSize.Medium,
			}),
		},
		{
			key = "VerboseLogging",
			name = "Verbose logging",
			description = "Log detailed install information to the output window.",
			control = e(Checkbox, {
				isChecked = ctx.settings.verboseLogging,
				onActivated = function()
					ctx.setSetting("verboseLogging", not ctx.settings.verboseLogging)
				end,
				size = InputSize.Medium,
			}),
		},
		{
			key = "Overrides",
			name = "Package Name Overrides",
			description = "Force a custom install name for packages matching a given name.",
			control = e(IconButton, {
				icon = Foundation.Enums.IconName.ChevronLargeRight,
				size = InputSize.Medium,
				variant = ButtonVariant.Standard,
				onActivated = function()
					nav.push("Overrides")
				end,
			}),
		},
	}

	local nextContentOrder = ReactHelpers.createNextOrder()
	local rowChildren: { [string]: any } = {
		ScrollLayout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		ScrollPadding = e("UIPadding", {
			PaddingLeft = UDim.new(0, 16),
			PaddingRight = UDim.new(0, 16),
		}),
	}
	for _, row in rows do
		rowChildren[row.key] = e(SettingRow, {
			name = row.name,
			description = row.description,
			footer = row.footer,
			control = row.control,
			LayoutOrder = nextContentOrder(),
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
				Text = "Settings",
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
			Scroll = e(ScrollView, {
				Size = UDim2.fromScale(1, 1),
				scroll = {
					scrollBarVisibility = Visibility.Auto,
					ScrollingDirection = Enum.ScrollingDirection.Y,
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					CanvasSize = UDim2.new(),
				},
			}, rowChildren),
		}),
	})
end

return Settings
