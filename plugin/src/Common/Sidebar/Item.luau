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
	badge: number?,
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

	local badgeCount = props.badge
	local hasBadge = badgeCount ~= nil and badgeCount > 0

	local iconSlot: React.ReactNode
	if compact and hasBadge then
		iconSlot = e(View, {
			Size = UDim2.fromOffset(28, 28),
			BackgroundTransparency = 1,
			LayoutOrder = nextOrder(),
			ClipsDescendants = false,
		}, {
			Icon = e(Icon, {
				name = props.icon,
				size = IconSize.Medium,
				style = foregroundStyle,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
			}),
			Dot = e("Frame", {
				Size = UDim2.fromOffset(8, 8),
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.fromScale(1, 0),
				BackgroundColor3 = tokens.Color.Content.Emphasis.Color3,
				BackgroundTransparency = tokens.Color.Content.Emphasis.Transparency,
				BorderSizePixel = 0,
				ZIndex = 2,
			}, {
				Corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
			}),
		})
	else
		iconSlot = e(Icon, {
			name = props.icon,
			size = IconSize.Medium,
			style = foregroundStyle,
			LayoutOrder = nextOrder(),
		})
	end

	local labelText = if hasBadge then `{props.text} ({badgeCount})` else props.text

	return e(View, {
		tag = tag,
		LayoutOrder = props.LayoutOrder,
		onActivated = props.onActivated,
		backgroundStyle = backgroundStyle,
		ClipsDescendants = false,
	}, {
		IconSlot = iconSlot,
		Label = not compact and e(Text, {
			tag = "grow auto-y text-align-x-left text-title-medium",
			Text = labelText,
			textStyle = foregroundStyle,
			LayoutOrder = nextOrder(),
		}),
	})
end

return Item
