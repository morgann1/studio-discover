local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local React = require(Packages.React)
local Foundation = require(Packages.Foundation)

local Navigation = require(Discover.Src.Navigation)
local SettingsModule = require(Discover.Src.Settings)

local View = Foundation.View
local Text = Foundation.Text
local IconButton = Foundation.IconButton
local Divider = Foundation.Divider

local InputSize = Foundation.Enums.InputSize
local ButtonVariant = Foundation.Enums.ButtonVariant

local e = React.createElement

local CONVENTIONS = { "Normal", "PascalCase" }

local function Settings()
	local nav = Navigation.useNavigation()
	local ctx = SettingsModule.useSettings()
	local current = ctx.settings.namingConvention

	local onBack = React.useCallback(function()
		nav.pop()
	end, { nav })

	local optionButtons = {}
	for i, convention in CONVENTIONS do
		local isSelected = convention == current
		local preview = if convention == "PascalCase" then "ReactRoblox" else "react-roblox"

		optionButtons["option_" .. convention] = e("TextButton", {
			Text = "",
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = if isSelected then Color3.fromRGB(40, 55, 85) else Color3.fromRGB(32, 34, 39),
			BorderSizePixel = 0,
			LayoutOrder = i,
			[React.Event.Activated] = function()
				ctx.setSetting("namingConvention", convention)
			end,
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
			OptionPadding = e("UIPadding", {
				PaddingLeft = UDim.new(0, 14),
				PaddingRight = UDim.new(0, 14),
				PaddingTop = UDim.new(0, 12),
				PaddingBottom = UDim.new(0, 12),
			}),
			OptionLayout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 4),
			}),
			Stroke = e("UIStroke", {
				Color = if isSelected then Color3.fromRGB(60, 120, 255) else Color3.fromRGB(55, 58, 66),
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
			Label = e("TextLabel", {
				Text = convention,
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				TextColor3 = Color3.fromRGB(247, 247, 248),
				FontFace = Font.fromEnum(Enum.Font.GothamBold),
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = 1,
			}),
			Preview = e("TextLabel", {
				Text = `Example: {preview}`,
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				TextColor3 = Color3.fromRGB(188, 190, 200),
				FontFace = Font.fromEnum(Enum.Font.Gotham),
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = 2,
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
				LayoutOrder = 1,
			}),
			SectionDesc = e(Text, {
				Text = "How package names are formatted when installed.",
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.fromScale(1, 0),
				tag = "text-caption-small text-align-x-left",
				LayoutOrder = 2,
			}),

			Options = e("Frame", {
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = 3,
			}, {
				OptionsLayout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 8),
				}),
				OptionButtons = e(React.Fragment, nil, optionButtons),
			}),
		}),
	})
end

return Settings
