--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const SourceLabel = require(StudioDiscover.Source.Common.SourceLabel)
const coreTypes = require(StudioDiscover.Libraries.Core.types)
const createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)

const Button = Foundation.Button
const Divider = Foundation.Divider
const Dropdown = Foundation.Dropdown
const Link = Foundation.Link
const Text = Foundation.Text
const View = Foundation.View
const ButtonVariant = Foundation.Enums.ButtonVariant
const InputSize = Foundation.Enums.InputSize
const Orientation = Foundation.Enums.Orientation

const e = React.createElement

const WIDE_DROPDOWN_WIDTH = 200
const WIDE_BUTTON_WIDTH = 120
const ACTIONS_GAP = 8
const HEAD_GAP = 16

-- Wide, the actions have a fixed width, and the identity takes the rest of the row.
const WIDE_ACTIONS_WIDTH = WIDE_DROPDOWN_WIDTH + ACTIONS_GAP + WIDE_BUTTON_WIDTH

-- What the install button says and does for the selected version.
export type Action = {
	read text: string,
	read isEmphasized: boolean,
	read isDisabled: boolean,
	read onActivated: () -> (),
}

--[[
	The package's name and by-line, then the version picker and the install button.
		With `isWide` the two share a row; otherwise the actions go underneath.
]]
const function Head(props: {
	read name: string,
	read scope: string,
	read registry: coreTypes.Registry,
	read versionItems: { Foundation.DropdownItem },
	read selectedVersion: string,
	read onVersionChanged: (version: string) -> (),
	read action: Action,
	read isWide: boolean,
	read onAuthorActivated: () -> (),
	read LayoutOrder: number?,
})
	const isWide = props.isWide
	const nextOrder = createNextOrder()

	const identity = e(View, {
		tag = {
			["auto-y col gap-xsmall"] = true,
			["size-full-0"] = not isWide,
		},
		Size = if isWide then UDim2.new(1, -(WIDE_ACTIONS_WIDTH + HEAD_GAP), 0, 0) else nil,
		LayoutOrder = nextOrder(),
	}, {
		Name = e(Text, {
			tag = {
				["size-full-0 auto-y content-emphasis text-align-x-left text-wrap"] = true,
				["text-heading-medium"] = isWide,
				["text-heading-small"] = not isWide,
			},
			Text = props.name,
			LayoutOrder = 1,
		}),
		ByLine = e(View, {
			tag = "size-full-0 auto-y row align-y-center gap-small",
			LayoutOrder = 2,
		}, {
			By = e(Text, {
				tag = "auto-xy text-body-medium content-muted",
				Text = "By",
				LayoutOrder = 1,
			}),
			Author = e(Link, {
				text = props.scope,
				size = InputSize.Medium,
				onActivated = props.onAuthorActivated,
				LayoutOrder = 2,
			}),
			Divider = e(View, {
				tag = "auto-x",
				Size = UDim2.fromOffset(0, 16),
				LayoutOrder = 3,
			}, {
				Line = e(Divider, {
					orientation = Orientation.Vertical,
				}),
			}),
			Source = e(SourceLabel, {
				registry = props.registry,
				isMuted = true,
				LayoutOrder = 4,
			}),
		}),
	})

	const actions = e(View, {
		tag = {
			["auto-y row align-y-center gap-small"] = true,
			["auto-x"] = isWide,
			["size-full-0"] = not isWide,
		},
		LayoutOrder = nextOrder(),
	}, {
		Version = e(View, {
			tag = {
				["auto-y"] = true,
				["grow"] = not isWide,
			},
			Size = if isWide then UDim2.fromOffset(WIDE_DROPDOWN_WIDTH, 0) else nil,
			LayoutOrder = 1,
		}, {
			Dropdown = e(Dropdown.Root, {
				label = "",
				value = props.selectedVersion,
				items = props.versionItems,
				onItemChanged = props.onVersionChanged,
				size = InputSize.Medium,
				width = UDim.new(1, 0),
				maxHeight = 240,
			}),
		}),
		Install = e(Button, {
			text = props.action.text,
			variant = if props.action.isEmphasized then ButtonVariant.Emphasis else ButtonVariant.Standard,
			size = InputSize.Medium,
			width = if isWide then UDim.new(0, WIDE_BUTTON_WIDTH) else nil,
			isDisabled = props.action.isDisabled,
			onActivated = props.action.onActivated,
			LayoutOrder = 2,
		}),
	})

	return e(View, {
		tag = {
			["size-full-0 auto-y gap-large"] = true,
			["row align-y-top"] = isWide,
			["col"] = not isWide,
		},
		LayoutOrder = props.LayoutOrder,
	}, {
		Identity = identity,
		Actions = actions,
	})
end

return Head
