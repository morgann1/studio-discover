local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Foundation = require(Packages.Foundation)
local React = require(Packages.React)

local View = Foundation.View
local Text = Foundation.Text
local Button = Foundation.Button

local InputSize = Foundation.Enums.InputSize
local ButtonVariant = Foundation.Enums.ButtonVariant

local e = React.createElement

type InstalledRowProps = {
	scope: string,
	name: string,
	version: string,
	realm: string,
	latestVersion: string?,
	onOpen: () -> (),
	onUpdate: (() -> ())?,
	onUninstall: () -> (),
	LayoutOrder: number,
}

local function InstalledRow(props: InstalledRowProps)
	local updateAvailable = props.latestVersion ~= nil and props.latestVersion ~= props.version
	local metaText = `v{props.version}  •  {props.realm}`
	if updateAvailable then
		metaText ..= `  •  update to v{props.latestVersion}`
	end

	return e(View, {
		Size = UDim2.new(1, 0, 0, 56),
		LayoutOrder = props.LayoutOrder,
	}, {
		RowLayout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 6),
		}),
		Padding = e("UIPadding", {
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
		}),

		Info = e("Frame", {
			Size = UDim2.new(1, if updateAvailable then -220 else -160, 1, 0),
			BackgroundTransparency = 1,
			LayoutOrder = 1,
		}, {
			InfoLayout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 2),
			}),
			Title = e(Text, {
				Text = `{props.scope}/{props.name}`,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.fromScale(1, 0),
				tag = "text-label-medium content-emphasis text-truncate-end text-align-x-left",
				LayoutOrder = 1,
			}),
			Meta = e(Text, {
				Text = metaText,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.fromScale(1, 0),
				tag = "text-caption-small text-align-x-left",
				LayoutOrder = 2,
			}),
		}),

		Open = e(Button, {
			text = "Open",
			variant = ButtonVariant.Standard,
			size = InputSize.Small,
			onActivated = props.onOpen,
			LayoutOrder = 2,
		}),

		Update = if updateAvailable and props.onUpdate
			then e(Button, {
				text = "Update",
				variant = ButtonVariant.Emphasis,
				size = InputSize.Small,
				onActivated = props.onUpdate,
				LayoutOrder = 3,
			})
			else nil,

		Uninstall = e(Button, {
			text = "Uninstall",
			variant = ButtonVariant.Utility,
			size = InputSize.Small,
			onActivated = props.onUninstall,
			LayoutOrder = 4,
		}),
	})
end

return InstalledRow
