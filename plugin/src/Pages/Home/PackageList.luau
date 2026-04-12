local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Foundation = require(Packages.Foundation)
local React = require(Packages.React)

local PackageCard = require(Discover.Src.Common.PackageCard)
local ReactHelpers = require(Discover.Src.Common.React)

local View = Foundation.View
local Text = Foundation.Text
local Divider = Foundation.Divider
local ScrollView = Foundation.ScrollView

local Visibility = Foundation.Enums.Visibility

local e = React.createElement

type PackageListItem = {
	scope: string,
	name: string,
	description: string?,
	version: string?,
	realm: string?,
	depCount: number?,
}

type PackageListProps = {
	header: string,
	items: { PackageListItem },
	onSelect: (scope: string, name: string) -> (),
}

local function PackageList(props: PackageListProps)
	local cardKey = ReactHelpers.createUniqueKey()
	local nextCardOrder = ReactHelpers.createNextOrder()

	local scrollChildren: { [string]: any } = {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}
	for _, pkg in props.items do
		scrollChildren[cardKey(`{pkg.scope}/{pkg.name}`)] = e(PackageCard, {
			name = pkg.name,
			scope = pkg.scope,
			description = pkg.description,
			version = pkg.version,
			realm = pkg.realm,
			depCount = pkg.depCount,
			LayoutOrder = nextCardOrder(),
			onSelect = props.onSelect,
		})
		scrollChildren[cardKey(`divider_{pkg.scope}/{pkg.name}`)] = e(Divider, {
			LayoutOrder = nextCardOrder(),
		})
	end

	local sectionOrder = ReactHelpers.createNextOrder()

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		SectionLayout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		Header = e(View, {
			Size = UDim2.new(1, 0, 0, 28),
			LayoutOrder = sectionOrder(),
			tag = "bg-surface-200",
		}, {
			Padding = e("UIPadding", {
				PaddingLeft = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 12),
			}),
			HeaderLayout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Label = e(Text, {
				Text = props.header,
				AutomaticSize = Enum.AutomaticSize.XY,
				tag = "text-caption-small content-muted",
			}),
		}),
		HeaderDivider = e(Divider, {
			LayoutOrder = sectionOrder(),
		}),
		ListWrap = e("Frame", {
			Size = UDim2.new(1, 0, 1, -29),
			BackgroundTransparency = 1,
			LayoutOrder = sectionOrder(),
		}, {
			List = e(ScrollView, {
				Size = UDim2.fromScale(1, 1),
				scroll = {
					scrollBarVisibility = Visibility.Auto,
					ScrollingDirection = Enum.ScrollingDirection.Y,
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					CanvasSize = UDim2.new(),
				},
			}, scrollChildren),
		}),
	})
end

return PackageList
