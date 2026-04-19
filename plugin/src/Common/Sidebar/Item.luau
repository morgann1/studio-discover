--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Foundation = require(StudioDiscover.Packages.Foundation)
local React = require(StudioDiscover.Packages.React)

local createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)

local Icon = Foundation.Icon
local Text = Foundation.Text
local View = Foundation.View
local IconSize = Foundation.Enums.IconSize
local useTokens = Foundation.Hooks.useTokens

local e = React.createElement

type Props = {
	text: string,
	icon: string,
	isActive: boolean,
	compact: boolean?,
	onActivated: () -> (),
	LayoutOrder: number?,
}

local function Item(props: Props)
	local tokens = useTokens()
	local compact = props.compact == true

	local backgroundStyle = if props.isActive then tokens.Color.ActionEmphasis.Background else nil
	local foregroundStyle = if props.isActive then tokens.Color.ActionEmphasis.Foreground else nil

	local tag = "size-full-1000 row align-y-center radius-medium"
		.. if compact then " align-x-center" else " gap-small padding-x-medium"

	local nextOrder = createNextOrder()

	return e(View, {
		tag = tag,
		LayoutOrder = props.LayoutOrder,
		onActivated = props.onActivated,
		backgroundStyle = backgroundStyle,
	}, {
		Icon = e(Icon, {
			name = props.icon,
			size = IconSize.Medium,
			style = foregroundStyle,
			LayoutOrder = nextOrder(),
		}),
		Label = not compact and e(Text, {
			tag = "grow auto-y text-align-x-left text-title-medium",
			Text = props.text,
			textStyle = foregroundStyle,
			LayoutOrder = nextOrder(),
		}),
	})
end

return Item
