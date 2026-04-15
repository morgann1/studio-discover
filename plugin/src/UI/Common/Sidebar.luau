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
local useCallback = React.useCallback
local useState = React.useState

-- Mirrors KDE Discover's drawer (DiscoverDrawer.qml: Kirigami.Units.gridUnit * 14).
local SIDEBAR_WIDTH = 252
local ITEM_HEIGHT = 28
-- Must match App.luau HEADER_HEIGHT so the sidebar search band and the
-- page-title header share the same Titlebar strip and divider line.
local SEARCH_ROW_HEIGHT = 38
local SEARCH_FIELD_HEIGHT = 22
local SEARCH_ICON_SIZE = 14

type SearchFieldProps = {
	text: string,
	placeholderText: string,
	onChanged: (text: string) -> (),
	onFocusLost: ((text: string, enterPressed: boolean) -> ())?,
}

local function SearchField(props: SearchFieldProps)
	local theme = useTheme()
	local hovered, setHovered = useState(false)
	local focused, setFocused = useState(false)

	local borderModifier = Enum.StudioStyleGuideModifier.Default
	if focused then
		borderModifier = Enum.StudioStyleGuideModifier.Selected
	elseif hovered then
		borderModifier = Enum.StudioStyleGuideModifier.Hover
	end

	local searchIcon = lucideIconProps("search")
	local clearIcon = lucideIconProps("x")
	local hasText = props.text ~= ""

	return e("Frame", {
		Size = UDim2.new(1, 0, 0, SEARCH_FIELD_HEIGHT),
		BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground),
		BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBorder, borderModifier),
		BorderMode = Enum.BorderMode.Inset,
		[React.Event.MouseEnter] = function()
			setHovered(true)
		end,
		[React.Event.MouseLeave] = function()
			setHovered(false)
		end,
	}, {
		Padding = e("UIPadding", {
			PaddingLeft = UDim.new(0, 6),
			PaddingRight = UDim.new(0, 4),
		}),
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 4),
		}),
		Icon = e("ImageLabel", {
			Size = UDim2.fromOffset(SEARCH_ICON_SIZE, SEARCH_ICON_SIZE),
			BackgroundTransparency = 1,
			Image = searchIcon.Image,
			ImageRectOffset = searchIcon.RectOffset,
			ImageRectSize = searchIcon.RectSize,
			ImageColor3 = theme:GetColor(Enum.StudioStyleGuideColor.DimmedText),
			ScaleType = Enum.ScaleType.Fit,
			LayoutOrder = 1,
		}),
		Input = e("TextBox", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Font = Constants.DefaultFont,
			TextSize = Constants.DefaultTextSize,
			TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
			PlaceholderText = props.placeholderText,
			PlaceholderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.DimmedText),
			Text = props.text,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			ClearTextOnFocus = false,
			ClipsDescendants = true,
			LayoutOrder = 2,
			[React.Change.Text] = function(rbx: TextBox)
				if rbx.Text ~= props.text then
					props.onChanged(rbx.Text)
				end
			end,
			[React.Event.Focused] = function()
				setFocused(true)
			end,
			[React.Event.FocusLost] = function(rbx: TextBox, enterPressed: boolean)
				setFocused(false)
				if props.onFocusLost then
					props.onFocusLost(rbx.Text, enterPressed)
				end
			end,
		}, {
			Flex = e("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }),
		}),
		ClearButton = if hasText
			then e("ImageButton", {
				Size = UDim2.fromOffset(SEARCH_ICON_SIZE, SEARCH_ICON_SIZE),
				BackgroundTransparency = 1,
				Image = clearIcon.Image,
				ImageRectOffset = clearIcon.RectOffset,
				ImageRectSize = clearIcon.RectSize,
				ImageColor3 = theme:GetColor(Enum.StudioStyleGuideColor.DimmedText),
				ScaleType = Enum.ScaleType.Fit,
				LayoutOrder = 3,
				[React.Event.Activated] = function()
					props.onChanged("")
				end,
			})
			else nil,
	})
end

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

	local modifier = Enum.StudioStyleGuideModifier.Default
	if props.active then
		modifier = Enum.StudioStyleGuideModifier.Selected
	elseif hovered then
		modifier = Enum.StudioStyleGuideModifier.Hover
	end

	local backgroundColor = theme:GetColor(Enum.StudioStyleGuideColor.Item, modifier)
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
		Corner = e("UICorner", {
			CornerRadius = UDim.new(0, 4),
		}),
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

	-- Search text stays in local state so keystrokes don't notify anything
	-- else. When the Wally search store lands, focus-loss / enter commits
	-- the text to the store — for now it just routes you to Home.
	local searchText, setSearchText = useState("")

	local onSearchCommit = useCallback(function(text: string, enterPressed: boolean)
		if enterPressed and text ~= "" and activeSection ~= "Home" then
			Navigation.resetTo("Home")
		end
	end, { activeSection } :: { any })

	local sectionChildren: { [string]: any } = {
		Padding = e("UIPadding", {
			PaddingLeft = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 4),
		}),
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 2),
		}),
	}
	for index, section in SECTIONS do
		sectionChildren[section.name] = e(SidebarItem, {
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
		BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
		BorderSizePixel = 0,
		LayoutOrder = 1,
	}, {
		SearchRow = e("Frame", {
			Size = UDim2.new(1, 0, 0, SEARCH_ROW_HEIGHT),
			BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Titlebar),
			BorderSizePixel = 0,
		}, {
			Padding = e("UIPadding", {
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 8),
				PaddingTop = UDim.new(0, 8),
				PaddingBottom = UDim.new(0, 8),
			}),
			Input = e(SearchField, {
				text = searchText,
				placeholderText = "Search packages",
				onChanged = setSearchText,
				onFocusLost = onSearchCommit,
			}),
		}),

		TopSeparator = e("Frame", {
			Position = UDim2.fromOffset(0, SEARCH_ROW_HEIGHT),
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
			BorderSizePixel = 0,
		}),

		SectionList = e("Frame", {
			Position = UDim2.fromOffset(0, SEARCH_ROW_HEIGHT + 1),
			Size = UDim2.new(1, -1, 1, -(SEARCH_ROW_HEIGHT + 1)),
			BackgroundTransparency = 1,
		}, sectionChildren),

		RightBorder = e("Frame", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromScale(1, 0),
			Size = UDim2.new(0, 1, 1, 0),
			BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border),
			BorderSizePixel = 0,
			ZIndex = 2,
		}),
	})
end

return Sidebar
