local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Foundation = require(Packages.Foundation)
local React = require(Packages.React)

local Pill = require(Discover.Src.Common.Pill)
local createNextOrder = require(Discover.Src.Util.createNextOrder)
local formatPackageKey = require(Discover.Src.Util.formatPackageKey)

local View = Foundation.View
local Text = Foundation.Text

local e = React.createElement

type PackageCardProps = {
	name: string,
	scope: string,
	description: string?,
	version: string?,
	realm: string?,
	dependencyCount: number?,
	onSelect: ((scope: string, name: string) -> ())?,
	LayoutOrder: number?,
}

local function PackageCard(props: PackageCardProps)
	local scope = props.scope
	local name = props.name
	local onSelect = props.onSelect

	local handleSelect = React.useCallback(function()
		if onSelect then
			onSelect(scope, name)
		end
	end, { scope, name, onSelect } :: { any })

	local nextPill = createNextOrder()
	local hasPills = false

	local pills = {
		PillLayout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Wraps = true,
			Padding = UDim.new(0, 6),
		}),
	}
	if props.version then
		hasPills = true
		pills.Version = e(Pill, { text = `v{props.version}`, LayoutOrder = nextPill() })
	end
	if props.realm and props.realm ~= "" then
		hasPills = true
		pills.Realm = e(Pill, { text = props.realm, LayoutOrder = nextPill() })
	end
	if props.dependencyCount and props.dependencyCount > 0 then
		hasPills = true
		pills.Deps = e(Pill, { text = `{props.dependencyCount} deps`, LayoutOrder = nextPill() })
	end

	return e(View, {
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		onActivated = handleSelect,
		stateLayer = { affordance = "Background" },
		LayoutOrder = props.LayoutOrder,
	}, {
		RowLayout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 12),
		}),
		Padding = e("UIPadding", {
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
			PaddingTop = UDim.new(0, 12),
			PaddingBottom = UDim.new(0, 12),
		}),

		Info = e("Frame", {
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = 1,
		}, {
			Flex = e("UIFlexItem", {
				FlexMode = Enum.UIFlexMode.Fill,
			}),
			InfoLayout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 4),
			}),
			Title = e(Text, {
				Text = formatPackageKey(props.scope, props.name),
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.fromScale(1, 0),
				tag = "text-label-medium content-emphasis text-truncate-end text-align-x-left",
				LayoutOrder = 1,
			}),
			Description = e(Text, {
				Text = props.description or "",
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.fromScale(1, 0),
				tag = "text-body-small content-muted text-align-x-left text-wrap",
				LayoutOrder = 2,
			}),
			Pills = if hasPills
				then e("Frame", {
					Size = UDim2.fromScale(1, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					LayoutOrder = 3,
				}, pills)
				else nil,
		}),
	})
end

return React.memo(PackageCard)
