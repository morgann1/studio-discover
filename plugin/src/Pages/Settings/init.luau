local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Foundation = require(Packages.Foundation)
local React = require(Packages.React)

local Navigation = require(Discover.Src.Navigation)
local OverrideRow = require(script.OverrideRow)
local ReactHelpers = require(Discover.Src.Common.React)
local SectionHeader = require(Discover.Src.Common.SectionHeader)
local SettingsModule = require(Discover.Src.Settings)

local View = Foundation.View
local Text = Foundation.Text
local IconButton = Foundation.IconButton
local Divider = Foundation.Divider
local Dropdown = Foundation.Dropdown
local TextInput = Foundation.TextInput
local ScrollView = Foundation.ScrollView

local InputSize = Foundation.Enums.InputSize
local ButtonVariant = Foundation.Enums.ButtonVariant
local Visibility = Foundation.Enums.Visibility

local e = React.createElement

local CONVENTION_ITEMS = {
	{ id = "Normal", text = "Normal (react-roblox)" },
	{ id = "PascalCase", text = "PascalCase (ReactRoblox)" },
}

local PREVIEW_SAMPLE = "react-roblox"

local function Settings()
	local nav = Navigation.useNavigation()
	local ctx = SettingsModule.useSettings()
	local current = ctx.settings.namingConvention
	local overrides = ctx.settings.nameOverrides

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
		if not string.find(trimmedKey, "/") then
			return
		end
		local next = table.clone(ctx.settings.nameOverrides)
		next[trimmedKey] = trimmedValue
		ctx.setSetting("nameOverrides", next)
		setNewKey("")
		setNewValue("")
	end, { ctx, newKey, newValue })

	local removeOverride = React.useCallback(function(key: string)
		local next = table.clone(ctx.settings.nameOverrides)
		next[key] = nil
		ctx.setSetting("nameOverrides", next)
	end, { ctx })

	local previewText = SettingsModule.formatPackageName(PREVIEW_SAMPLE, current)

	local sortedKeys = {}
	for k in overrides do
		table.insert(sortedKeys, k)
	end
	table.sort(sortedKeys)

	local overrideRows: { [string]: any } = {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 4),
		}),
	}
	local overrideRowKey = ReactHelpers.createUniqueKey()
	local nextOverrideOrder = ReactHelpers.createNextOrder()
	for _, key in sortedKeys do
		overrideRows[overrideRowKey(key)] = e(OverrideRow, {
			keyName = key,
			value = overrides[key],
			onRemove = removeOverride,
			LayoutOrder = nextOverrideOrder(),
		})
	end

	local nextContentOrder = ReactHelpers.createNextOrder()

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

				NamingSection = e("Frame", {
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					LayoutOrder = nextContentOrder(),
				}, {
					Layout = e("UIListLayout", {
						FillDirection = Enum.FillDirection.Vertical,
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 8),
					}),
					Header = e(SectionHeader, { text = "Naming Convention", LayoutOrder = 1 }),
					Description = e(Text, {
						Text = "How package names are formatted when installed.",
						AutomaticSize = Enum.AutomaticSize.Y,
						Size = UDim2.fromScale(1, 0),
						TextWrapped = true,
						tag = "text-caption-small content-muted text-align-x-left",
						LayoutOrder = 2,
					}),
					DropdownWrap = e("Frame", {
						Size = UDim2.new(1, 0, 0, 40),
						BackgroundTransparency = 1,
						LayoutOrder = 3,
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
					Preview = e(Text, {
						Text = `Example: {PREVIEW_SAMPLE} → {previewText}`,
						AutomaticSize = Enum.AutomaticSize.Y,
						Size = UDim2.fromScale(1, 0),
						tag = "text-caption-small content-muted text-align-x-left",
						LayoutOrder = 4,
					}),
				}),

				OverridesSection = e("Frame", {
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					LayoutOrder = nextContentOrder(),
				}, {
					Layout = e("UIListLayout", {
						FillDirection = Enum.FillDirection.Vertical,
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 8),
					}),
					Header = e(SectionHeader, { text = "Package Name Overrides", LayoutOrder = 1 }),
					Description = e(Text, {
						Text = "Force a custom display/install name for a specific package. Use the form scope/name (e.g. sleitnick/signal).",
						AutomaticSize = Enum.AutomaticSize.Y,
						Size = UDim2.fromScale(1, 0),
						TextWrapped = true,
						tag = "text-caption-small content-muted text-align-x-left",
						LayoutOrder = 2,
					}),
					List = if #sortedKeys > 0
						then e("Frame", {
							Size = UDim2.new(1, 0, 0, 0),
							AutomaticSize = Enum.AutomaticSize.Y,
							BackgroundTransparency = 1,
							LayoutOrder = 3,
						}, overrideRows)
						else e(Text, {
							Text = "No overrides yet.",
							AutomaticSize = Enum.AutomaticSize.Y,
							Size = UDim2.fromScale(1, 0),
							tag = "text-caption-small content-muted text-align-x-left",
							LayoutOrder = 3,
						}),
					AddRow = e("Frame", {
						Size = UDim2.new(1, 0, 0, 40),
						BackgroundTransparency = 1,
						LayoutOrder = 4,
					}, {
						Layout = e("UIListLayout", {
							FillDirection = Enum.FillDirection.Horizontal,
							SortOrder = Enum.SortOrder.LayoutOrder,
							VerticalAlignment = Enum.VerticalAlignment.Center,
							HorizontalFlex = Enum.UIFlexAlignment.Fill,
							Padding = UDim.new(0, 8),
						}),
						KeyInputWrap = e("Frame", {
							Size = UDim2.new(1, 0, 1, 0),
							BackgroundTransparency = 1,
							LayoutOrder = 1,
						}, {
							Flex = e("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }),
							Input = e(TextInput, {
								text = newKey,
								label = "",
								placeholder = "scope/name",
								size = InputSize.Medium,
								width = UDim.new(1, 0),
								onChanged = function(text: string)
									setNewKey(text)
								end,
							}),
						}),
						ValueInputWrap = e("Frame", {
							Size = UDim2.new(1, 0, 1, 0),
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
							Size = UDim2.new(0, 40, 0, 40),
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
		}),
	})
end

return Settings
