local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local React = require(Packages.React)

local useStudioTheme = require(Discover.Src.Common.useStudioTheme)

local e = React.createElement

type SelectableTextProps = {
	text: string,
	Size: UDim2?,
	LayoutOrder: number?,
	emphasis: boolean?,
}

local function SelectableText(props: SelectableTextProps)
	useStudioTheme()
	local theme = settings().Studio.Theme
	local colorRole = if props.emphasis
		then Enum.StudioStyleGuideColor.BrightText
		else Enum.StudioStyleGuideColor.MainText

	return e("TextBox", {
		Text = props.text,
		TextEditable = false,
		ClearTextOnFocus = false,
		MultiLine = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
		TextSize = 14,
		TextColor3 = theme:GetColor(colorRole),
		TextTruncate = Enum.TextTruncate.AtEnd,
		Size = props.Size or UDim2.new(1, 0, 0, 20),
		LayoutOrder = props.LayoutOrder,
	})
end

return SelectableText
