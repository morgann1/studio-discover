--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)

const Divider = Foundation.Divider
const Text = Foundation.Text
const View = Foundation.View

const e = React.createElement

-- A titled block of a screen's content, separated from the one above by a divider.
const function Section(props: {
	read title: string,
	read children: React.Node,
	read LayoutOrder: number?,
})
	const nextOrder = createNextOrder()

	return e(View, {
		tag = "size-full-0 auto-y col gap-small",
		LayoutOrder = props.LayoutOrder,
	}, {
		TopDivider = e(Divider, { LayoutOrder = nextOrder() }),
		Heading = e(Text, {
			tag = "size-full-0 auto-y text-title-small content-emphasis text-align-x-left",
			Text = props.title,
			LayoutOrder = nextOrder(),
		}),
		Body = e(View, {
			tag = "size-full-0 auto-y col gap-small",
			LayoutOrder = nextOrder(),
		}, props.children),
	})
end

return Section
