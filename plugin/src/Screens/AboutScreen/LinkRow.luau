--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Foundation = require(StudioDiscover.Packages.Foundation)
local React = require(StudioDiscover.Packages.React)

local createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)

local Text = Foundation.Text
local View = Foundation.View

local e = React.createElement

type Props = {
	label: string,
	url: string,
	LayoutOrder: number?,
}

-- Static label + URL pair. Plugin security can't trigger external browser
-- opens, so the URL is shown as plain text for the user to copy by hand.
local function LinkRow(props: Props)
	local nextOrder = createNextOrder()

	return e(View, {
		tag = "size-full-0 auto-y row align-y-center gap-medium",
		LayoutOrder = props.LayoutOrder,
	}, {
		Label = e(Text, {
			tag = "auto-xy text-body-small content-muted",
			Text = `{props.label}:`,
			LayoutOrder = nextOrder(),
		}),
		Url = e(Text, {
			tag = "grow auto-y text-body-small content-default text-align-x-left text-truncate",
			Text = props.url,
			LayoutOrder = nextOrder(),
		}),
	})
end

return LinkRow
