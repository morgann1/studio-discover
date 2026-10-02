--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)

const Divider = Foundation.Divider
const Text = Foundation.Text

const e = React.createElement

const ROW_HEIGHT = 48
const ROW_GAP = 12
const COLUMN_GAP = 2
const ROW_PADDING_Y = 10

-- One settings row: the name and description on the left, `control` on the right.
const function Setting(props: {
	read name: string,
	read description: string,
	read control: React.Node,
	read LayoutOrder: number?,
})
	const nextOrder = createNextOrder()
	const nextRowOrder = createNextOrder()
	const nextTextOrder = createNextOrder()

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
					Control = props.control,
				}),
			}),
		}),

		Divider = e(Divider, {
			LayoutOrder = nextOrder(),
		}),
	})
end

return Setting
