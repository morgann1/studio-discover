local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Foundation = require(Packages.Foundation)
local React = require(Packages.React)

local Navigation = require(Discover.Src.Navigation)
local ReactHelpers = require(Discover.Src.Common.React)
local SettingsModule = require(Discover.Src.Settings)

local Text = Foundation.Text
local View = Foundation.View
local Chip = Foundation.Chip
local Divider = Foundation.Divider
local IconButton = Foundation.IconButton
local TextInput = Foundation.TextInput
local ScrollView = Foundation.ScrollView

local InputSize = Foundation.Enums.InputSize
local ButtonVariant = Foundation.Enums.ButtonVariant
local ChipSize = Foundation.Enums.ChipSize
local Visibility = Foundation.Enums.Visibility

local e = React.createElement

local function Overrides()
	local nav = Navigation.useNavigation()
	local settingsContext = SettingsModule.useSettings()
	local overrides = settingsContext.settings.nameOverrides

	local newKey, setNewKey = React.useState("")
	local newValue, setNewValue = React.useState("")

	local onBack = React.useCallback(function()
		nav.pop()
	end, { nav })

	local addOverride = React.useCallback(function()
		local trimmedKey = string.lower((string.gsub(newKey, "^%s*(.-)%s*$", "%1")))
		local trimmedValue = (string.gsub(newValue, "^%s*(.-)%s*$", "%1"))
		if trimmedKey == "" or trimmedValue == "" then
			return
		end
		local updated = table.clone(overrides)
		updated[trimmedKey] = trimmedValue
		settingsContext.setSetting("nameOverrides", updated)
		setNewKey("")
		setNewValue("")
	end, { settingsContext, overrides, newKey, newValue } :: { any })

	local removeOverride = React.useCallback(function(key: string)
		local updated = table.clone(overrides)
		updated[key] = nil
		settingsContext.setSetting("nameOverrides", updated)
	end, { settingsContext, overrides } :: { any })

	local sortedKeys = {}
	for k in overrides do
		table.insert(sortedKeys, k)
	end
	table.sort(sortedKeys)

	local nextOrder = ReactHelpers.createNextOrder()
	local chipKey = ReactHelpers.createUniqueKey()

	local chips: { [string]: any } = {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Wraps = true,
			Padding = UDim.new(0, 6),
		}),
	}
	for _, key in sortedKeys do
		local k = key
		chips[chipKey(k)] = e(Chip, {
			text = `{k} → {overrides[k]}`,
			size = ChipSize.Small,
			trailing = {
				iconName = "icons/navigation/close_small",
				onActivated = function()
					removeOverride(k)
				end,
			},
			onActivated = function()
				removeOverride(k)
			end,
			LayoutOrder = nextOrder(),
		})
	end

	local contentOrder = ReactHelpers.createNextOrder()

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
				Text = "Package Name Overrides",
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
			}, {
				ScrollLayout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 8),
				}),
				ScrollPadding = e("UIPadding", {
					PaddingLeft = UDim.new(0, 16),
					PaddingRight = UDim.new(0, 16),
					PaddingTop = UDim.new(0, 12),
					PaddingBottom = UDim.new(0, 12),
				}),

				Description = e(Text, {
					Text = "Force a custom install name for packages matching a given name, regardless of scope.",
					AutomaticSize = Enum.AutomaticSize.Y,
					Size = UDim2.fromScale(1, 0),
					TextWrapped = true,
					tag = "text-caption-small content-muted text-align-x-left",
					LayoutOrder = contentOrder(),
				}),

				Chips = #sortedKeys > 0 and e("Frame", {
					Size = UDim2.fromScale(1, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					LayoutOrder = contentOrder(),
				}, chips),

				AddRow = e("Frame", {
					Size = UDim2.new(1, 0, 0, 40),
					BackgroundTransparency = 1,
					LayoutOrder = contentOrder(),
				}, {
					RowLayout = e("UIListLayout", {
						FillDirection = Enum.FillDirection.Horizontal,
						SortOrder = Enum.SortOrder.LayoutOrder,
						VerticalAlignment = Enum.VerticalAlignment.Center,
						HorizontalFlex = Enum.UIFlexAlignment.Fill,
						Padding = UDim.new(0, 8),
					}),
					KeyInputWrap = e("Frame", {
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						LayoutOrder = 1,
					}, {
						Flex = e("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }),
						Input = e(TextInput, {
							text = newKey,
							label = "",
							placeholder = "package name",
							size = InputSize.Medium,
							width = UDim.new(1, 0),
							onChanged = function(text: string)
								setNewKey(text)
							end,
						}),
					}),
					ValueInputWrap = e("Frame", {
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						LayoutOrder = 2,
					}, {
						Flex = e("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }),
						Input = e(TextInput, {
							text = newValue,
							label = "",
							placeholder = "DisplayName",
							size = InputSize.Medium,
							width = UDim.new(1, 0),
							onChanged = function(text: string)
								setNewValue(text)
							end,
						}),
					}),
					AddButtonWrap = e("Frame", {
						Size = UDim2.fromOffset(40, 40),
						BackgroundTransparency = 1,
						LayoutOrder = 3,
					}, {
						Flex = e("UIFlexItem", { FlexMode = Enum.UIFlexMode.None }),
						Button = e(IconButton, {
							icon = Foundation.Enums.IconName.PlusLarge,
							size = InputSize.Medium,
							variant = ButtonVariant.Emphasis,
							onActivated = addOverride,
						}),
					}),
				}),
			}),
		}),
	})
end

return Overrides
