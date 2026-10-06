--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const NoticeStore = require(StudioDiscover.Source.NoticeStore)

const Snackbar = Foundation.Snackbar
const View = Foundation.View

const e = React.createElement

-- The current notice, floating at the bottom center of the widget over the screen.
const function Notice(props: {
	read ZIndex: number?,
}): React.Node
	const notice = NoticeStore.useNotice()
	if notice == nil then
		return nil
	end

	return e(View, {
		tag = "auto-xy padding-medium",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		ZIndex = props.ZIndex,
	}, {
		Snackbar = e(Snackbar, {
			title = notice.text,
			onClose = NoticeStore.dismiss,
		}),
	})
end

return Notice
