--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Foundation = require(StudioDiscover.Packages.Foundation)
local React = require(StudioDiscover.Packages.React)

local Header = require(script.Header)
local createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)

local View = Foundation.View

local e = React.createElement

type Props = {
	title: string?,
	onBack: (() -> ())?,
	header: React.ReactNode?,
	children: React.ReactNode?,
}

local function Screen(props: Props)
	local nextOrder = createNextOrder()

	local headerElement = props.header
	if headerElement == nil and props.title ~= nil then
		headerElement = e(Header, {
			title = props.title,
			onBack = props.onBack,
			LayoutOrder = nextOrder(),
		})
	else
		nextOrder()
	end

	return e(View, {
		tag = "size-full col",
	}, {
		Header = headerElement,
		Content = e(View, {
			tag = "size-full-0 grow",
			LayoutOrder = nextOrder(),
		}, props.children),
	})
end

return Screen
