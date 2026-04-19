--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Cryo = require(StudioDiscover.Packages.Cryo)
local Foundation = require(StudioDiscover.Packages.Foundation)
local React = require(StudioDiscover.Packages.React)

local createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)

local Divider = Foundation.Divider
local Dropdown = Foundation.Dropdown
local Text = Foundation.Text
local Toggle = Foundation.Toggle
local InputSize = Foundation.Enums.InputSize

local e = React.createElement

local ROW_HEIGHT = 48
local ROW_GAP = 12
local COLUMN_GAP = 2
local ROW_PADDING_Y = 10

type Props = {
	name: string,
	description: string,
	value: any?,
	onChange: ((any) -> ())?,
	options: { string }?,
	input: React.ReactNode?,
	LayoutOrder: number?,
}

-- Uses a raw Frame + explicit UIListLayout instead of Foundation's tag
-- layout: `align-y-center` was unreliable under auto-sized parents.
local function Setting(props: Props)
	local nextOrder = createNextOrder()
	local nextRowOrder = createNextOrder()
	local nextTextOrder = createNextOrder()

	local control: React.ReactNode = nil
	if props.input ~= nil then
		control = props.input
	elseif props.options ~= nil then
		local items = Cryo.List.map(props.options, function(opt: string): Foundation.DropdownItem
			return { id = opt, text = opt }
		end)
		control = e(Dropdown.Root, {
			label = "",
			value = props.value,
			items = items,
			onItemChanged = props.onChange,
			size = InputSize.Small,
			width = UDim.new(0, 200),
		})
	else
		control = e(Toggle, {
			isChecked = props.value,
			onActivated = props.onChange,
			size = InputSize.Small,
		})
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
	}, {
		OuterLayout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),

		RowWrapper = e("Frame", {
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = nextOrder(),
		}, {
			RowWrapperPadding = e("UIPadding", {
				PaddingTop = UDim.new(0, ROW_PADDING_Y),
				PaddingBottom = UDim.new(0, ROW_PADDING_Y),
			}),

			Row = e("Frame", {
				Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
				BackgroundTransparency = 1,
			}, {
				RowLayout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					HorizontalAlignment = Enum.HorizontalAlignment.Left,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, ROW_GAP),
				}),

				TextColumn = e("Frame", {
					Size = UDim2.fromScale(0, 1),
					BackgroundTransparency = 1,
					LayoutOrder = nextRowOrder(),
				}, {
					TextFlex = e("UIFlexItem", {
						FlexMode = Enum.UIFlexMode.Grow,
					}),
					TextLayout = e("UIListLayout", {
						FillDirection = Enum.FillDirection.Vertical,
						VerticalAlignment = Enum.VerticalAlignment.Center,
						HorizontalAlignment = Enum.HorizontalAlignment.Left,
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, COLUMN_GAP),
					}),

					Name = e(Text, {
						Text = props.name,
						Size = UDim2.fromScale(1, 0),
						AutomaticSize = Enum.AutomaticSize.Y,
						tag = "text-title-medium content-emphasis text-align-x-left",
						TextTruncate = Enum.TextTruncate.AtEnd,
						LayoutOrder = nextTextOrder(),
					}),
					Description = e(Text, {
						Text = props.description,
						Size = UDim2.fromScale(1, 0),
						AutomaticSize = Enum.AutomaticSize.Y,
						tag = "text-body-small content-muted text-align-x-left",
						TextTruncate = Enum.TextTruncate.AtEnd,
						LayoutOrder = nextTextOrder(),
					}),
				}),

				ControlWrapper = e("Frame", {
					Size = UDim2.fromOffset(0, 0),
					AutomaticSize = Enum.AutomaticSize.XY,
					BackgroundTransparency = 1,
					LayoutOrder = nextRowOrder(),
				}, {
					Control = control,
				}),
			}),
		}),

		Divider = e(Divider, {
			LayoutOrder = nextOrder(),
		}),
	})
end

return Setting
