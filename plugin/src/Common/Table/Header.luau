--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const Cells = require(script.Parent.Cells)
const createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)
const types = require(script.Parent.types)

const Divider = Foundation.Divider
const Text = Foundation.Text
const View = Foundation.View
const Orientation = Foundation.Enums.Orientation

const e = React.createElement

const HEIGHT = 32
const GAP = 12

--[[
	The column labels above a table. Each label after the first has a divider in the
		gap before it, so the labels line up with the values below them. A column
		without a label, such as one for row actions, gets no divider.
]]
const function Header(props: {
	read columns: { types.Column },
	read LayoutOrder: number?,
})
	const nextOrder = createNextOrder()
	const labels: { [string]: React.Node } = {}

	for index, column in props.columns do
		labels[column.key] = e(View, {
			tag = "size-full",
		}, {
			Divider = index > 1 and column.label ~= "" and e(View, {
				Size = UDim2.new(0, 1, 1, -12),
				Position = UDim2.fromOffset(-GAP // 2, 6),
			}, {
				Line = e(Divider, {
					orientation = Orientation.Vertical,
				}),
			}),
			Label = e(Text, {
				tag = "size-full text-caption-medium content-muted text-align-x-left",
				Text = column.label,
			}),
		})
	end

	return e(View, {
		tag = "size-full-0 auto-y col",
		LayoutOrder = props.LayoutOrder,
	}, {
		Labels = e(View, {
			tag = "size-full-0",
			Size = UDim2.new(1, 0, 0, HEIGHT),
			LayoutOrder = nextOrder(),
		}, {
			Cells = e(Cells, {
				columns = props.columns,
				cells = labels,
				gap = GAP,
			}),
		}),
		Divider = e(Divider, {
			LayoutOrder = nextOrder(),
		}),
	})
end

return Header
