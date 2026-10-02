--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const Cells = require(script.Parent.Cells)
const createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)
const types = require(script.Parent.types)

const Divider = Foundation.Divider
const View = Foundation.View

const e = React.createElement

const GAP = 12

-- One table row, `height` pixels tall, that highlights on hover when it has `onActivated`.
const function Row(props: {
	read columns: { types.Column },
	read cells: { [string]: React.Node },
	read height: number,
	read onActivated: (() -> ())?,
	read LayoutOrder: number?,
})
	const nextOrder = createNextOrder()

	return e(View, {
		tag = "size-full-0 auto-y col",
		LayoutOrder = props.LayoutOrder,
	}, {
		Body = e(View, {
			Size = UDim2.new(1, 0, 0, props.height),
			onActivated = props.onActivated,
			LayoutOrder = nextOrder(),
		}, {
			Cells = e(Cells, {
				columns = props.columns,
				cells = props.cells,
				gap = GAP,
			}),
		}),
		Divider = e(Divider, {
			LayoutOrder = nextOrder(),
		}),
	})
end

return Row
