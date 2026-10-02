--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)

const Divider = Foundation.Divider
const Icon = Foundation.Icon
const StatusBadge = Foundation.StatusBadge
const Text = Foundation.Text
const View = Foundation.View
const IconName = Foundation.Enums.IconName
const IconSize = Foundation.Enums.IconSize
const StatusBadgeVariant = Foundation.Enums.StatusBadgeVariant

const e = React.createElement

const ROW_HEIGHT = 44

--[[
	Every version, newest first, marking the latest, the installed one, and the one
		selected. Picking a row selects that version, like the dropdown does.
]]
const function Versions(props: {
	read versions: { string },
	read selected: string,
	read installed: string?,
	read onSelected: (version: string) -> (),
	read LayoutOrder: number?,
})
	const nextOrder = createNextOrder()
	const rows: { [string]: React.Node } = {}

	for index, version in props.versions do
		const nextRowOrder = createNextOrder()

		rows[version] = e(View, {
			tag = "size-full-0 auto-y col",
			LayoutOrder = nextOrder(),
		}, {
			Body = e(View, {
				tag = "size-full-0 row align-y-center gap-small",
				Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
				onActivated = function()
					props.onSelected(version)
				end,
				LayoutOrder = nextRowOrder(),
			}, {
				Version = e(Text, {
					tag = "auto-xy text-body-medium content-emphasis",
					Text = version,
					LayoutOrder = 1,
				}),
				Latest = index == 1 and e(StatusBadge, {
					text = "Latest",
					variant = StatusBadgeVariant.Standard,
					LayoutOrder = 2,
				}),
				Installed = version == props.installed and e(StatusBadge, {
					text = "Installed",
					variant = StatusBadgeVariant.Success,
					LayoutOrder = 3,
				}),
				Spacer = e(View, {
					tag = "grow",
					LayoutOrder = 4,
				}),
				Selected = version == props.selected and e(Icon, {
					name = IconName.Check,
					size = IconSize.Small,
					LayoutOrder = 5,
				}),
			}),
			Divider = e(Divider, {
				LayoutOrder = nextRowOrder(),
			}),
		})
	end

	return e(View, {
		tag = "size-full-0 auto-y col",
		LayoutOrder = props.LayoutOrder,
	}, rows)
end

return Versions
