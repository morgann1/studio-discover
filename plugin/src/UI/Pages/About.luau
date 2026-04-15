local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local React = require(Packages.React)
local StudioComponents = require(Packages.StudioComponents)

local Settings = require(Discover.Src.UI.Settings)
local createNextOrder = require(Discover.Src.UI.Util.createNextOrder)
local formatPackageName = require(Discover.Src.UI.Util.formatPackageName)
local lucideIconProps = require(Discover.Src.UI.Common.lucideIconProps)
local useAtom = require(Discover.Src.UI.Common.useAtom)

local Constants = StudioComponents.Constants
local useTheme = StudioComponents.useTheme

local e = React.createElement

local DESCRIPTION = "A Roblox Studio plugin for browsing and installing Wally packages."

local LINKS = {
	{ label = "Get Involved", url = "https://github.com/morgann1/studio-discover" },
	{ label = "Report a Bug", url = "https://github.com/morgann1/studio-discover/issues" },
}

local AUTHORS = {
	"morgann1",
}

-- Mirror plugin/wally.toml [dependencies]. Description is pulled from each
-- package's wally.toml when present; leave empty otherwise.
local COMPONENTS = {
	{ scopeName = "jsdotlua/react", version = "17.2.1", description = "" },
	{ scopeName = "jsdotlua/react-roblox", version = "17.2.1", description = "" },
	{ scopeName = "jsdotlua/react-otter", version = "1.2.1", description = "" },
	{ scopeName = "littensy/charm", version = "0.10.0", description = "" },
	{
		scopeName = "sircfenner/studiocomponents",
		version = "1.2.0",
		description = "React components for building Roblox Studio plugins",
	},
	{
		scopeName = "latte-soft/lucide-icons",
		version = "0.1.2",
		description = "Library to Use the Lucide Icon Set in Roblox",
	},
	{ scopeName = "morgann1/zzlib", version = "0.1.0", description = "" },
}

local TITLE_TEXT_SIZE = 20
local SECTION_HEADER_TEXT_SIZE = 14
local ICON_SIZE = 40

local function SectionHeader(props: { text: string, layoutOrder: number })
	local theme = useTheme()
	return e("TextLabel", {
		Text = props.text,
		Font = Enum.Font.SourceSansSemibold,
		TextSize = SECTION_HEADER_TEXT_SIZE,
		TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.SubText),
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		LayoutOrder = props.layoutOrder,
	})
end

local function ComponentRow(props: {
	scopeName: string,
	version: string,
	description: string,
	layoutOrder: number,
})
	local theme = useTheme()
	local convention = useAtom(Settings.atoms.namingConvention)

	local descriptionText = props.description
	if descriptionText == "" then
		local bareName = string.match(props.scopeName, "[^/]+$") or props.scopeName
		descriptionText = `{formatPackageName(bareName, convention)} has no provided description.`
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = props.layoutOrder,
	}, {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			Padding = UDim.new(0, 8),
		}),
		TextBlock = e("Frame", {
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = 1,
		}, {
			Flex = e("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }),
			Layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 2),
			}),
			Name = e("TextLabel", {
				Text = props.scopeName,
				Font = Constants.DefaultFont,
				TextSize = Constants.DefaultTextSize,
				TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 18),
				LayoutOrder = 1,
			}),
			Description = e("TextLabel", {
				Text = descriptionText,
				Font = Constants.DefaultFont,
				TextSize = Constants.DefaultTextSize,
				TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.DimmedText),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				TextWrapped = true,
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.fromScale(1, 0),
				LayoutOrder = 2,
			}),
		}),
		Version = e("TextLabel", {
			Text = props.version,
			Font = Constants.DefaultFont,
			TextSize = Constants.DefaultTextSize,
			TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.DimmedText),
			TextXAlignment = Enum.TextXAlignment.Right,
			TextYAlignment = Enum.TextYAlignment.Top,
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 18),
			LayoutOrder = 2,
		}),
	})
end

local function About()
	local theme = useTheme()
	local nextOrder = createNextOrder()
	local headerIcon = lucideIconProps("package")

	local linkButtons: { [string]: any } = {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
		}),
	}
	for index, link in LINKS do
		linkButtons[link.label] = e(StudioComponents.Button, {
			Text = link.label,
			Size = UDim2.fromOffset(110, Constants.DefaultButtonHeight),
			LayoutOrder = index,
			Disabled = true,
		})
	end

	local componentRows: { [string]: any } = {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
		}),
	}
	for index, component in COMPONENTS do
		componentRows[component.scopeName] = e(ComponentRow, {
			scopeName = component.scopeName,
			version = component.version,
			description = component.description,
			layoutOrder = index,
		})
	end

	local authorRows: { [string]: any } = {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 4),
		}),
	}
	for index, author in AUTHORS do
		authorRows[author] = e("TextLabel", {
			Text = author,
			Font = Constants.DefaultFont,
			TextSize = Constants.DefaultTextSize,
			TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 18),
			LayoutOrder = index,
		})
	end

	return e(StudioComponents.ScrollFrame, {
		Size = UDim2.fromScale(1, 1),
		PaddingLeft = UDim.new(0, 16),
		PaddingRight = UDim.new(0, 16),
		PaddingTop = UDim.new(0, 16),
		PaddingBottom = UDim.new(0, 16),
		Layout = {
			ClassName = "UIListLayout",
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 16),
		},
	}, {
		Header = e("Frame", {
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = nextOrder(),
		}, {
			Layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 12),
			}),
			Icon = e("ImageLabel", {
				Size = UDim2.fromOffset(ICON_SIZE, ICON_SIZE),
				BackgroundTransparency = 1,
				Image = headerIcon.Image,
				ImageRectOffset = headerIcon.RectOffset,
				ImageRectSize = headerIcon.RectSize,
				ImageColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
				ScaleType = Enum.ScaleType.Fit,
				LayoutOrder = 1,
			}),
			TextWrap = e("Frame", {
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = 2,
			}, {
				Flex = e("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }),
				Layout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 2),
				}),
				Title = e("TextLabel", {
					Text = "Studio Discover",
					Font = Enum.Font.SourceSansSemibold,
					TextSize = TITLE_TEXT_SIZE,
					TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, TITLE_TEXT_SIZE + 4),
					LayoutOrder = 1,
				}),
				Description = e("TextLabel", {
					Text = DESCRIPTION,
					Font = Constants.DefaultFont,
					TextSize = Constants.DefaultTextSize,
					TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.DimmedText),
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					TextWrapped = true,
					BackgroundTransparency = 1,
					AutomaticSize = Enum.AutomaticSize.Y,
					Size = UDim2.fromScale(1, 0),
					LayoutOrder = 2,
				}),
			}),
		}),

		LinksHeader = e(SectionHeader, { text = "License", layoutOrder = nextOrder() }),
		Links = e("Frame", {
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = nextOrder(),
		}, linkButtons),

		ComponentsHeader = e(SectionHeader, { text = "Packages in use", layoutOrder = nextOrder() }),
		Components = e("Frame", {
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = nextOrder(),
		}, componentRows),

		AuthorsHeader = e(SectionHeader, { text = "Authors", layoutOrder = nextOrder() }),
		Authors = e("Frame", {
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = nextOrder(),
		}, authorRows),
	})
end

return About
