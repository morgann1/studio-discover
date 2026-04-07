local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Foundation = require(Packages.Foundation)
local React = require(Packages.React)

local Pill = require(Discover.Src.Common.Pill)

local View = Foundation.View
local Text = Foundation.Text
local Button = Foundation.Button
local IconButton = Foundation.IconButton

local InputSize = Foundation.Enums.InputSize
local ButtonVariant = Foundation.Enums.ButtonVariant

local e = React.createElement

type InstalledRowProps = {
	scope: string,
	name: string,
	version: string,
	realm: string,
	latestVersion: string?,
	onSelect: (scope: string, name: string) -> (),
	onUpdate: ((scope: string, name: string) -> ())?,
	onUninstall: (scope: string, name: string) -> (),
	LayoutOrder: number,
}

local function InstalledRow(props: InstalledRowProps)
	local scope = props.scope
	local name = props.name
	local onSelect = props.onSelect
	local onUpdate = props.onUpdate
	local onUninstall = props.onUninstall
	local updateAvailable = props.latestVersion ~= nil and props.latestVersion ~= props.version

	local handleSelect = React.useCallback(function()
		onSelect(scope, name)
	end, { scope, name, onSelect } :: { any })

	local handleUpdate = React.useCallback(function()
		if onUpdate then
			onUpdate(scope, name)
		end
	end, { scope, name, onUpdate } :: { any })

	local handleUninstall = React.useCallback(function()
		onUninstall(scope, name)
	end, { scope, name, onUninstall } :: { any })

	local pillOrder = 0
	local function nextPill()
		pillOrder += 1
		return pillOrder
	end

	local pills: { [string]: any } = {
		PillLayout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Wraps = true,
			Padding = UDim.new(0, 6),
		}),
		Version = e(Pill, { text = `v{props.version}`, LayoutOrder = nextPill() }),
		Realm = e(Pill, { text = props.realm, LayoutOrder = nextPill() }),
	}
	if updateAvailable then
		pills.Update = e(Pill, {
			text = `update v{props.latestVersion}`,
			LayoutOrder = nextPill(),
			emphasis = true,
		})
	end

	return e(View, {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = props.LayoutOrder,
		onActivated = handleSelect,
		stateLayer = { affordance = "Background" },
	}, {
		RowLayout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			HorizontalFlex = Enum.UIFlexAlignment.Fill,
			Padding = UDim.new(0, 8),
		}),
		Padding = e("UIPadding", {
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
			PaddingTop = UDim.new(0, 12),
			PaddingBottom = UDim.new(0, 12),
		}),

		Info = e("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = 1,
		}, {
			Flex = e("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }),
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
			Pills = e("Frame", {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = 2,
			}, pills),
		}),

		UpdateWrap = if updateAvailable
			then e("Frame", {
				Size = UDim2.new(0, 80, 0, 32),
				BackgroundTransparency = 1,
				LayoutOrder = 2,
			}, {
				Button = e(Button, {
					text = "Update",
					variant = ButtonVariant.Emphasis,
					size = InputSize.Small,
					onActivated = handleUpdate,
				}),
			})
			else nil,

		UninstallWrap = e("Frame", {
			Size = UDim2.new(0, 32, 0, 32),
			BackgroundTransparency = 1,
			LayoutOrder = 3,
		}, {
			Button = e(IconButton, {
				icon = Foundation.Enums.IconName.TrashCan,
				size = InputSize.Small,
				variant = ButtonVariant.Standard,
				onActivated = handleUninstall,
			}),
		}),
	})
end

return React.memo(InstalledRow)
