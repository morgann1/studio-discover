--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Foundation = require(StudioDiscover.Packages.Foundation)
local React = require(StudioDiscover.Packages.React)

local createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)

local Divider = Foundation.Divider
local Text = Foundation.Text
local View = Foundation.View

local e = React.createElement

type Props = {
	title: string,
	children: React.ReactNode?,
	LayoutOrder: number?,
}

local function Section(props: Props)
	local nextOrder = createNextOrder()

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
