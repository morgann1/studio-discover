--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const ToolButton = require(StudioDiscover.Source.Common.ToolButton)
const iconName = require(StudioDiscover.Source.Util.iconName)

const Divider = Foundation.Divider
const TextInput = Foundation.TextInput
const View = Foundation.View
const InputSize = Foundation.Enums.InputSize

const e = React.createElement

--[[
	One display-name rule: the package name, the name to give it, and a remove button.
		With `isStacked`, the two inputs stack so the row fits a docked widget, and each
		carries its own label. Side by side, `ColumnLabels` labels them once above the
		rows.
]]
const function Row(props: {
	read name: string,
	read displayName: string,
	read isStacked: boolean,
	read onNameChanged: (string) -> (),
	read onDisplayNameChanged: (string) -> (),
	read onRemove: () -> (),
	read LayoutOrder: number?,
})
	const isStacked = props.isStacked
	const inputWidth = if isStacked then UDim.new(1, 0) else UDim.new(0.5, -4)

	return e(View, {
		tag = "size-full-0 auto-y col gap-medium",
		LayoutOrder = props.LayoutOrder,
	}, {
		Row = e(View, {
			tag = "size-full-0 auto-y row align-y-center gap-small",
			LayoutOrder = 1,
		}, {
			Inputs = e(View, {
				tag = {
					["grow auto-y gap-small"] = true,
					["col"] = isStacked,
					["row"] = not isStacked,
				},
				LayoutOrder = 1,
			}, {
				Name = e(TextInput, {
					text = props.name,
					label = if isStacked then "Package" else "",
					placeholder = "Package name",
					size = InputSize.Medium,
					width = inputWidth,
					onChanged = props.onNameChanged,
					LayoutOrder = 1,
				}),
				DisplayName = e(TextInput, {
					text = props.displayName,
					label = if isStacked then "Display name" else "",
					placeholder = "Display name",
					size = InputSize.Medium,
					width = inputWidth,
					onChanged = props.onDisplayNameChanged,
					LayoutOrder = 2,
				}),
			}),
			Remove = e(ToolButton, {
				icon = iconName("TrashCan"),
				label = "Remove",
				onActivated = props.onRemove,
				LayoutOrder = 2,
			}),
		}),
		Divider = isStacked and e(Divider, {
			LayoutOrder = 2,
		}),
	})
end

return Row
