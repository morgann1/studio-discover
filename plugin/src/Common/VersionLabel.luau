--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const isBreakingUpdate = require(StudioDiscover.Libraries.Semver.isBreakingUpdate)

const StatusBadge = Foundation.StatusBadge
const Text = Foundation.Text
const View = Foundation.View
const StatusBadgeShape = Foundation.Enums.StatusBadgeShape
const StatusBadgeSize = Foundation.Enums.StatusBadgeSize
const StatusBadgeVariant = Foundation.Enums.StatusBadgeVariant

const e = React.createElement

--[[
	An installed version, or the step from it to `latest` in the link colour, flagged
		Major when the step is a breaking change.
]]
const function VersionLabel(props: {
	read version: string,
	read latest: string?,
	read LayoutOrder: number?,
})
	const latest = props.latest

	return e(View, {
		tag = "auto-xy row align-y-center gap-small",
		LayoutOrder = props.LayoutOrder,
	}, {
		Version = e(Text, {
			tag = {
				["auto-xy text-body-medium"] = true,
				["content-link"] = latest ~= nil,
				["content-default"] = latest == nil,
			},
			Text = if latest ~= nil then `{props.version} → {latest}` else props.version,
			LayoutOrder = 1,
		}),
		Major = latest ~= nil and isBreakingUpdate(props.version, latest) and e(StatusBadge, {
			text = "Major",
			variant = StatusBadgeVariant.Warning,
			shape = StatusBadgeShape.Box,
			size = StatusBadgeSize.XSmall,
			LayoutOrder = 2,
		}),
	})
end

return VersionLabel
