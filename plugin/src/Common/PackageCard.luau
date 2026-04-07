local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Foundation = require(Packages.Foundation)
local React = require(Packages.React)

local Pill = require(Discover.Src.Common.Pill)

local View = Foundation.View
local Text = Foundation.Text
local Button = Foundation.Button

local InputSize = Foundation.Enums.InputSize
local ButtonVariant = Foundation.Enums.ButtonVariant

local e = React.createElement

type PackageCardProps = {
	name: string,
	scope: string,
	description: string?,
	version: string?,
	realm: string?,
	depCount: number?,
	isInstalled: boolean?,
	onSelect: ((scope: string, name: string) -> ())?,
	onInstall: ((scope: string, name: string, version: string) -> ())?,
	LayoutOrder: number?,
}

local function PackageCard(props: PackageCardProps)
	local scope = props.scope
	local name = props.name
	local version = props.version
	local onSelect = props.onSelect
	local onInstall = props.onInstall

	local handleSelect = React.useCallback(function()
		if onSelect then
			onSelect(scope, name)
		end
	end, { scope, name, onSelect } :: { any })

	local handleInstall = React.useCallback(function()
		if onInstall and version then
			onInstall(scope, name, version)
		end
	end, { scope, name, version, onInstall } :: { any })

	local pillOrder = 0
	local function nextPill()
		pillOrder += 1
		return pillOrder
	end

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
		pills[`pill_version`] = e(Pill, { text = `v{props.version}`, LayoutOrder = nextPill() })
	end
	if props.realm and props.realm ~= "" then
		pills[`pill_realm`] = e(Pill, { text = props.realm, LayoutOrder = nextPill() })
	end
	if props.depCount and props.depCount > 0 then
		pills[`pill_deps`] = e(Pill, { text = `{props.depCount} deps`, LayoutOrder = nextPill() })
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
				Text = `{props.scope}/{props.name}`,
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
			Pills = if pillOrder > 0
				then e("Frame", {
					Size = UDim2.fromScale(1, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					LayoutOrder = 3,
				}, pills)
				else nil,
		}),

		Action = e(Button, {
			text = if props.isInstalled then "Installed" else "Install",
			variant = if props.isInstalled then ButtonVariant.Standard else ButtonVariant.Emphasis,
			size = InputSize.Small,
			isDisabled = props.isInstalled or onInstall == nil or version == nil,
			onActivated = handleInstall,
			LayoutOrder = 2,
		}),
	})
end

return React.memo(PackageCard)
