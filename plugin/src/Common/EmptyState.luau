--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const Message = require(StudioDiscover.Source.Common.Message)

const Empty = Foundation.Empty
const View = Foundation.View
const IconSize = Foundation.Enums.IconSize

const e = React.createElement

--[[
	Foundation's empty state in the middle of a screen's body: an icon over the text,
		with a button when there is somewhere to go next. For a place with nothing to
		list, such as no packages installed. Loading, failures, and filters with no
		matches use `Message`.
]]
const function EmptyState(props: {
	read icon: string,
	read text: string,
	read action: Message.Action?,
})
	const action = props.action

	return e(View, {
		tag = "size-full padding-large",
	}, {
		Empty = e(Empty, {
			icon = { name = props.icon, size = IconSize.Large },
			text = props.text,
			button = if action ~= nil then { text = action.text, onActivated = action.onActivated } else nil,
		}),
	})
end

return EmptyState
