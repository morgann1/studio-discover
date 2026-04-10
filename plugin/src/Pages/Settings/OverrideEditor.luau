local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Foundation = require(Packages.Foundation)
local React = require(Packages.React)

local ReactHelpers = require(Discover.Src.Common.React)
local SectionHeader = require(Discover.Src.Common.SectionHeader)
local SettingsModule = require(Discover.Src.Settings)

local Text = Foundation.Text
local Chip = Foundation.Chip
local Divider = Foundation.Divider
local IconButton = Foundation.IconButton
local TextInput = Foundation.TextInput

local InputSize = Foundation.Enums.InputSize
local ButtonVariant = Foundation.Enums.ButtonVariant
local ChipSize = Foundation.Enums.ChipSize

local e = React.createElement

type OverrideEditorProps = {
	LayoutOrder: number,
}

local function OverrideEditor(props: OverrideEditorProps)
	local ctx = SettingsModule.useSettings()
	local overrides = ctx.settings.nameOverrides

	local newKey, setNewKey = React.useState("")
	local newValue, setNewValue = React.useState("")

	local addOverride = React.useCallback(function()
		local trimmedKey = string.lower((string.gsub(newKey, "^%s*(.-)%s*$", "%1")))
		local trimmedValue = (string.gsub(newValue, "^%s*(.-)%s*$", "%1"))
		if trimmedKey == "" or trimmedValue == "" then
			return
		end
		local updated = table.clone(overrides)
		updated[trimmedKey] = trimmedValue
		ctx.setSetting("nameOverrides", updated)
		setNewKey("")
		setNewValue("")
	end, { ctx, overrides, newKey, newValue } :: { any })

	local removeOverride = React.useCallback(function(key: string)
		local updated = table.clone(overrides)
		updated[key] = nil
		ctx.setSetting("nameOverrides", updated)
	end, { ctx, overrides } :: { any })

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

	return e("Frame", {
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
	}, {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
		}),
		Padding = e("UIPadding", {
			PaddingTop = UDim.new(0, 16),
			PaddingBottom = UDim.new(0, 12),
		}),

		Header = e(SectionHeader, { text = "Package Name Overrides", LayoutOrder = 1 }),

		Description = e(Text, {
			Text = "Force a custom install name for packages matching a given name, regardless of scope.",
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.fromScale(1, 0),
			TextWrapped = true,
			tag = "text-caption-small content-muted text-align-x-left",
			LayoutOrder = 2,
		}),

		Chips = #sortedKeys > 0 and e("Frame", {
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = 3,
		}, chips),

		AddRow = e("Frame", {
			Size = UDim2.new(1, 0, 0, 40),
			BackgroundTransparency = 1,
			LayoutOrder = 4,
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

		BottomDivider = e(Divider, { LayoutOrder = 5 }),
	})
end

return OverrideEditor
