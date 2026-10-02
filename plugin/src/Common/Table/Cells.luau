--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const types = require(script.Parent.types)

const View = Foundation.View

const e = React.createElement

--[[
	Lays `cells` out under `columns` in one row, keyed and ordered by column. Shared
		by the header and every row, so their columns always line up.
]]
const function Cells(props: {
	read columns: { types.Column },
	read cells: { [string]: React.Node },
	read gap: number,
})
	const children: { [string]: React.Node } = {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, props.gap),
		}),
	}

	for index, column in props.columns do
		const width = column.width

		children[column.key] = e(View, {
			tag = "row align-y-center",
			Size = if width ~= nil then UDim2.new(0, width, 1, 0) else UDim2.fromScale(0, 1),
			LayoutOrder = index,
		}, {
			Flex = width == nil and e("UIFlexItem", {
				FlexMode = Enum.UIFlexMode.Grow,
			}),
			Content = props.cells[column.key],
		})
	end

	return e(View, {
		tag = "size-full padding-x-large",
	}, children)
end

return Cells
