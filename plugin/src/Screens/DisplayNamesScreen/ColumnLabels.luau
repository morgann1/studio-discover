--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const Text = Foundation.Text
const View = Foundation.View

const e = React.createElement

-- Matches the remove button at the end of each `Row`, so the labels sit over the inputs.
const REMOVE_WIDTH = 32

const function label(text: string, layoutOrder: number): React.Node
	return e(Text, {
		tag = "auto-y text-body-small content-emphasis text-align-x-left",
		Size = UDim2.new(0.5, -4, 0, 0),
		Text = text,
		LayoutOrder = layoutOrder,
	})
end

--[[
	"Package" and "Display name" over the columns of side-by-side rows. Stacked rows
		label their own inputs instead.
]]
const function ColumnLabels(props: {
	read LayoutOrder: number?,
})
	return e(View, {
		tag = "size-full-0 auto-y row gap-small",
		LayoutOrder = props.LayoutOrder,
	}, {
		Labels = e(View, {
			tag = "grow auto-y row gap-small",
			LayoutOrder = 1,
		}, {
			Name = label("Package", 1),
			DisplayName = label("Display name", 2),
		}),
		Remove = e(View, {
			Size = UDim2.fromOffset(REMOVE_WIDTH, 0),
			LayoutOrder = 2,
		}),
	})
end

return ColumnLabels
