--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const Button = Foundation.Button
const Text = Foundation.Text
const View = Foundation.View
const ButtonVariant = Foundation.Enums.ButtonVariant
const InputSize = Foundation.Enums.InputSize

const e = React.createElement

export type Action = {
	read text: string,
	read onActivated: () -> (),
}

--[[
	A line of muted text in the middle of a screen's body, for loading, failures, and
		filters with no matches, with a button when there is somewhere to go next. A
		place with nothing to list uses `EmptyState`.
]]
const function Message(props: {
	read text: string,
	read action: Action?,
})
	const action = props.action

	return e(View, {
		tag = "size-full col align-x-center align-y-center gap-medium padding-large",
	}, {
		Text = e(Text, {
			tag = "size-full-0 auto-y text-body-medium content-muted text-wrap",
			Text = props.text,
			LayoutOrder = 1,
		}),
		Action = action ~= nil and e(Button, {
			text = action.text,
			variant = ButtonVariant.Standard,
			size = InputSize.Small,
			onActivated = action.onActivated,
			LayoutOrder = 2,
		}),
	})
end

return Message
