--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const Header = require(script.Header)
const createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)

const View = Foundation.View

const e = React.createElement

-- The shell of a screen: a header with the title and an optional back button, and the body below.
const function Screen(props: {
	read title: string,
	read onBack: (() -> ())?,
	read children: React.Node,
})
	const nextOrder = createNextOrder()

	return e(View, {
		tag = "size-full col",
	}, {
		Header = e(Header, {
			title = props.title,
			onBack = props.onBack,
			LayoutOrder = nextOrder(),
		}),
		Content = e(View, {
			tag = "size-full-0 grow",
			LayoutOrder = nextOrder(),
		}, props.children),
	})
end

return Screen
