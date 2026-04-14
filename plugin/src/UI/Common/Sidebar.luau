local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local React = require(Packages.React)
local StudioComponents = require(Packages.StudioComponents)

local Navigation = require(Discover.Src.UI.Navigation)
local lucideIconProps = require(Discover.Src.UI.Common.lucideIconProps)
local useAtom = require(Discover.Src.UI.Common.useAtom)

local Constants = StudioComponents.Constants
local useTheme = StudioComponents.useTheme

local e = React.createElement
local useState = React.useState

-- Mirrors KDE Discover's drawer (DiscoverDrawer.qml: Kirigami.Units.gridUnit * 14).
local SIDEBAR_WIDTH = 252
local ITEM_HEIGHT = 28

local SECTIONS = {
	{ name = "Home", icon = "home" },
	{ name = "Installed", icon = "package" },
	{ name = "Updates", icon = "download" },
	{ name = "Settings", icon = "settings" },
	{ name = "About", icon = "info" },
}

type SidebarItemProps = {
	name: string,
	icon: string,
	active: boolean,
	layoutOrder: number,
	onActivated: () -> (),
}

local function SidebarItem(props: SidebarItemProps)
	local theme = useTheme()
	local hovered, setHovered = useState(false)

	local backgroundStyle = Enum.StudioStyleGuideColor.Item
	local modifier = Enum.StudioStyleGuideModifier.Default
	if props.active then
		modifier = Enum.StudioStyleGuideModifier.Selected
	elseif hovered then
		modifier = Enum.StudioStyleGuideModifier.Hover
	end
	local backgroundColor = theme:GetColor(backgroundStyle, modifier)
	local textColor = theme:GetColor(Enum.StudioStyleGuideColor.MainText, modifier)
	local iconAsset = lucideIconProps(props.icon)

	return e("TextButton", {
		Size = UDim2.new(1, 0, 0, ITEM_HEIGHT),
		Text = "",
		BackgroundColor3 = backgroundColor,
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
		Padding = e("UIPadding", {
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
		}),
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 8),
		}),
		Icon = e("ImageLabel", {
			Size = UDim2.fromOffset(16, 16),
			BackgroundTransparency = 1,
			Image = iconAsset.Image,
			ImageRectOffset = iconAsset.RectOffset,
			ImageRectSize = iconAsset.RectSize,
			ImageColor3 = textColor,
			ScaleType = Enum.ScaleType.Fit,
			LayoutOrder = 1,
		}),
		LabelWrap = e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			LayoutOrder = 2,
		}, {
			Flex = e("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }),
			Label = e("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Font = Constants.DefaultFont,
				TextSize = Constants.DefaultTextSize,
				TextColor3 = textColor,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				Text = props.name,
			}),
		}),
	})
end

local function Sidebar()
	local theme = useTheme()
	local activeSection = useAtom(Navigation.activeSection)

	local items: { [string]: any } = {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 2),
		}),
		Padding = e("UIPadding", {
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
		}),
	}
	for index, section in SECTIONS do
		items[section.name] = e(SidebarItem, {
			name = section.name,
			icon = section.icon,
			active = activeSection == section.name,
			layoutOrder = index,
			onActivated = function()
				Navigation.resetTo(section.name)
			end,
		})
	end

	return e("Frame", {
		Size = UDim2.new(0, SIDEBAR_WIDTH, 1, 0),
		BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ViewPortBackground),
		BorderSizePixel = 0,
		LayoutOrder = 1,
	}, items)
end

return Sidebar
