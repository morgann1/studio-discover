local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local React = require(Packages.React)
local StudioComponents = require(Packages.StudioComponents)

local Navigation = require(Discover.Src.UI.Navigation)
local PackageCard = require(Discover.Src.UI.Common.PackageCard)

local useTheme = StudioComponents.useTheme

local e = React.createElement

local SECTION_HEADER_TEXT_SIZE = 16
local GRID_COLUMNS = 2
local GRID_PADDING = 8
local CARD_HEIGHT = 64

local MOST_POPULAR = {
	{ scopeName = "evaera/cmdr", description = "Extensible command console for Roblox developers" },
	{
		scopeName = "jsdotlua/react",
		description = "A comprehensive, but not exhaustive, translation of ReactJS 17.x into Luau.",
	},
	{ scopeName = "evaera/promise", description = "Promise implementation for Roblox" },
	{ scopeName = "jsdotlua/jest", description = "Delightful testing for Luau." },
	{ scopeName = "sleitnick/knit", description = "Knit is a lightweight game framework" },
	{
		scopeName = "howmanysmall/janitor",
		description = "A garbage collector object implementation for Roblox, featuring support for custom cleanup methods, Promises, and instance linking.",
	},
}

local function SectionHeader(props: { text: string, layoutOrder: number })
	local theme = useTheme()
	return e("TextLabel", {
		Text = props.text,
		Font = Enum.Font.SourceSansSemibold,
		TextSize = SECTION_HEADER_TEXT_SIZE,
		TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 22),
		LayoutOrder = props.layoutOrder,
	})
end

local function Home()
	local cardChildren: { [string]: any } = {
		Layout = e("UIGridLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			FillDirectionMaxCells = GRID_COLUMNS,
			SortOrder = Enum.SortOrder.LayoutOrder,
			CellSize = UDim2.new(1 / GRID_COLUMNS, -GRID_PADDING, 0, CARD_HEIGHT),
			CellPadding = UDim2.fromOffset(GRID_PADDING, GRID_PADDING),
		}),
	}
	for index, package in MOST_POPULAR do
		cardChildren[package.scopeName] = e(PackageCard, {
			scopeName = package.scopeName,
			description = package.description,
			layoutOrder = index,
			onActivated = function()
				Navigation.push("Package", { scopeName = package.scopeName })
			end,
		})
	end

	local rows = math.ceil(#MOST_POPULAR / GRID_COLUMNS)
	local gridHeight = rows * CARD_HEIGHT + math.max(0, rows - 1) * GRID_PADDING

	return e(StudioComponents.ScrollFrame, {
		Size = UDim2.fromScale(1, 1),
		PaddingLeft = UDim.new(0, 16),
		PaddingRight = UDim.new(0, 16),
		PaddingTop = UDim.new(0, 16),
		PaddingBottom = UDim.new(0, 16),
		Layout = {
			ClassName = "UIListLayout",
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 12),
		},
	}, {
		MostPopularHeader = e(SectionHeader, { text = "Most Popular", layoutOrder = 1 }),
		MostPopularGrid = e("Frame", {
			Size = UDim2.new(1, 0, 0, gridHeight),
			BackgroundTransparency = 1,
			LayoutOrder = 2,
		}, cardChildren),
	})
end

return Home
