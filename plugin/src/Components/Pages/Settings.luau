local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Foundation = require(Packages.Foundation)
local React = require(Packages.React)

local Navigation = require(Discover.Src.Navigation)
local SettingsModule = require(Discover.Src.Settings)
local ReactHelpers = require(Discover.Src.Utility.React)

local View = Foundation.View
local Text = Foundation.Text
local IconButton = Foundation.IconButton
local Divider = Foundation.Divider
local Dropdown = Foundation.Dropdown

local InputSize = Foundation.Enums.InputSize
local ButtonVariant = Foundation.Enums.ButtonVariant

local e = React.createElement

local CONVENTION_ITEMS = {
	{ id = "Normal", text = "Normal (react-roblox)" },
	{ id = "PascalCase", text = "PascalCase (ReactRoblox)" },
}

local function Settings()
	local nav = Navigation.useNavigation()
	local ctx = SettingsModule.useSettings()
	local current = ctx.settings.namingConvention

	local onBack = React.useCallback(function()
		nav.pop()
	end, { nav })

	local nextContentOrder = ReactHelpers.createNextOrder()

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
			Size = UDim2.new(1, 0, 1, -50),
			BackgroundTransparency = 1,
			LayoutOrder = 3,
		}, {
			ContentLayout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 12),
			}),
			ContentPadding = e("UIPadding", {
				PaddingLeft = UDim.new(0, 16),
				PaddingRight = UDim.new(0, 16),
				PaddingTop = UDim.new(0, 16),
				PaddingBottom = UDim.new(0, 16),
			}),

			SectionTitle = e(Text, {
				Text = "Naming Convention",
				AutomaticSize = Enum.AutomaticSize.XY,
				tag = "text-label-medium content-emphasis",
				LayoutOrder = nextContentOrder(),
			}),
			SectionDesc = e(Text, {
				Text = "How package names are formatted when installed.",
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.fromScale(1, 0),
				tag = "text-caption-small text-align-x-left",
				LayoutOrder = nextContentOrder(),
			}),
			NamingConvention = e(Dropdown.Root, {
				label = "",
				size = InputSize.Small,
				width = UDim.new(1, 0),
				value = current,
				items = CONVENTION_ITEMS,
				onItemChanged = function(id: string)
					ctx.setSetting("namingConvention", id)
				end,
				LayoutOrder = nextContentOrder(),
			}),
		}),
	})
end

return Settings
