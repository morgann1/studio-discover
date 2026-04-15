local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local React = require(Packages.React)
local StudioComponents = require(Packages.StudioComponents)

local Constants = StudioComponents.Constants
local useTheme = StudioComponents.useTheme

local e = React.createElement
local useState = React.useState

type PackageCardProps = {
	scopeName: string,
	description: string?,
	layoutOrder: number?,
	onActivated: (() -> ())?,
}

local function PackageCard(props: PackageCardProps)
	local theme = useTheme()
	local hovered, setHovered = useState(false)

	local modifier = if hovered then Enum.StudioStyleGuideModifier.Hover else Enum.StudioStyleGuideModifier.Default
	local description = props.description or ""

	return e("TextButton", {
		Size = UDim2.fromScale(1, 1),
		Text = "",
		BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.TableItem, modifier),
		BorderSizePixel = 0,
		AutoButtonColor = false,
		LayoutOrder = props.layoutOrder,
		[React.Event.Activated] = props.onActivated,
		[React.Event.MouseEnter] = function()
			setHovered(true)
		end,
		[React.Event.MouseLeave] = function()
			setHovered(false)
		end,
	}, {
		Corner = e("UICorner", { CornerRadius = UDim.new(0, 6) }),
		Stroke = e("UIStroke", {
			Color = theme:GetColor(Enum.StudioStyleGuideColor.Border),
			Thickness = 1,
		}),
		Padding = e("UIPadding", {
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
		}),
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 4),
		}),
		ScopeName = e("TextLabel", {
			Text = props.scopeName,
			Font = Enum.Font.SourceSansSemibold,
			TextSize = Constants.DefaultTextSize,
			TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 18),
			LayoutOrder = 1,
		}),
		Description = e("TextLabel", {
			Text = description,
			Font = Constants.DefaultFont,
			TextSize = Constants.DefaultTextSize,
			TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.DimmedText),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = true,
			TextTruncate = Enum.TextTruncate.AtEnd,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			LayoutOrder = 2,
		}, {
			Flex = e("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }),
		}),
	})
end

return PackageCard
