--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const MajorBadge = require(StudioDiscover.Source.Common.MajorBadge)
const isBreakingUpdate = require(StudioDiscover.Libraries.Semver.isBreakingUpdate)

const Text = Foundation.Text
const View = Foundation.View

const e = React.createElement

--[[
	An installed version, or the step from it to `latest` with the new version in
		emphasis, flagged Major when the step is a breaking change.
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
			tag = "auto-xy text-body-medium content-default",
			Text = if latest ~= nil then `{props.version} →` else props.version,
			LayoutOrder = 1,
		}),
		Latest = latest ~= nil and e(Text, {
			tag = "auto-xy text-body-medium content-emphasis",
			Text = latest,
			LayoutOrder = 2,
		}),
		Major = latest ~= nil and isBreakingUpdate(props.version, latest) and e(MajorBadge, {
			LayoutOrder = 3,
		}),
	})
end

return VersionLabel
