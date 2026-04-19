--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Foundation = require(StudioDiscover.Packages.Foundation)
local React = require(StudioDiscover.Packages.React)

local createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)

local Text = Foundation.Text
local View = Foundation.View
local useTokens = Foundation.Hooks.useTokens

local e = React.createElement

type Props = {
	label: string,
	url: string,
	LayoutOrder: number?,
}

-- Native TextBox (not Foundation.Text) so users can select and Ctrl+C the
-- URL. Plugins can't open browsers and `CopyToClipboard` is built-in only.
local function LinkRow(props: Props)
	local tokens = useTokens()
	local nextOrder = createNextOrder()

	local typography = tokens.Typography.BodySmall
	local foreground = tokens.Color.Content.Default

	return e(View, {
		tag = "size-full-0 auto-y row align-y-center gap-medium",
		LayoutOrder = props.LayoutOrder,
	}, {
		Label = e(Text, {
			tag = "auto-xy text-body-small content-muted",
			Text = `{props.label}:`,
			LayoutOrder = nextOrder(),
		}),
		UrlCell = e(View, {
			tag = "grow auto-y",
			LayoutOrder = nextOrder(),
		}, {
			Box = e("TextBox", {
				Text = props.url,
				TextEditable = false,
				ClearTextOnFocus = false,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = foreground.Color3,
				TextTransparency = foreground.Transparency,
				FontFace = typography.Font,
				TextSize = typography.FontSize,
				LineHeight = typography.LineHeight,
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}),
		}),
	})
end

return LinkRow
