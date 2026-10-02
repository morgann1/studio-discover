--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)
const useTokens = require(StudioDiscover.Source.Common.useTokens)

const Icon = Foundation.Icon
const Text = Foundation.Text
const View = Foundation.View
const IconSize = Foundation.Enums.IconSize

const e = React.createElement

--[[
	One sidebar entry. When compact it shows only the icon, with a dot for a nonzero
		`badge`; when expanded the count follows the label.
]]
const function Item(props: {
	read text: string,
	read icon: string,
	read isActive: boolean,
	read compact: boolean,
	read badge: number?,
	read onActivated: () -> (),
	read LayoutOrder: number?,
})
	const tokens = useTokens()
	const nextOrder = createNextOrder()

	const backgroundStyle = if props.isActive then tokens.Color.ActionEmphasis.Background else nil
	const foregroundStyle = if props.isActive then tokens.Color.ActionEmphasis.Foreground else nil

	const badge = props.badge
	const hasBadge = badge ~= nil and badge > 0

	local iconSlot: React.Node
	if props.compact and hasBadge then
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

	return e(View, {
		tag = if props.compact
			then "size-full-1000 row align-y-center radius-medium align-x-center"
			else "size-full-1000 row align-y-center radius-medium gap-small padding-x-medium",
		LayoutOrder = props.LayoutOrder,
		onActivated = props.onActivated,
		backgroundStyle = backgroundStyle,
		ClipsDescendants = false,
	}, {
		IconSlot = iconSlot,
		Label = not props.compact and e(Text, {
			tag = "grow auto-y text-align-x-left text-title-medium",
			Text = if hasBadge then `{props.text} ({badge})` else props.text,
			textStyle = foregroundStyle,
			LayoutOrder = nextOrder(),
		}),
	})
end

return Item
