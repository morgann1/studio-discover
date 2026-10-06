--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)

const Text = Foundation.Text
const View = Foundation.View

const e = React.createElement

-- The row's gap-medium, which every column but the last has after it.
const GAP = 12

export type Fact = {
	read label: string,
	read value: React.Node,
}

-- Labelled values in equal columns, `columns` to a row, wrapping onto more rows as needed.
const function Facts(props: {
	read facts: { Fact },
	read columns: number,
	read LayoutOrder: number?,
})
	const nextOrder = createNextOrder()
	const cells: { [string]: React.Node } = {}

	-- The gaps between columns are shared out, so the last column ends at the row's edge.
	const columns = props.columns
	const width = UDim2.new(1 / columns, -GAP * (columns - 1) / columns, 0, 0)

	for _, fact in props.facts do
		cells[fact.label] = e(View, {
			tag = "auto-y col gap-xxsmall",
			Size = width,
			LayoutOrder = nextOrder(),
		}, {
			Label = e(Text, {
				tag = "size-full-0 auto-y text-caption-medium content-muted text-align-x-left",
				Text = fact.label,
				LayoutOrder = 1,
			}),
			Value = e(View, {
				tag = "size-full-0 auto-y row align-y-center",
				LayoutOrder = 2,
			}, {
				Value = fact.value,
			}),
		})
	end

	return e(View, {
		tag = "size-full-0 auto-y row wrap gap-medium",
		LayoutOrder = props.LayoutOrder,
	}, cells)
end

return Facts
