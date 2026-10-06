--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const StatusBadge = Foundation.StatusBadge
const StatusBadgeShape = Foundation.Enums.StatusBadgeShape
const StatusBadgeSize = Foundation.Enums.StatusBadgeSize
const StatusBadgeVariant = Foundation.Enums.StatusBadgeVariant

const e = React.createElement

-- Flags a version step that is a breaking change, beside the version it applies to.
const function MajorBadge(props: {
	read LayoutOrder: number?,
})
	return e(StatusBadge, {
		text = "Major",
		variant = StatusBadgeVariant.Warning,
		shape = StatusBadgeShape.Box,
		size = StatusBadgeSize.XSmall,
		LayoutOrder = props.LayoutOrder,
	})
end

return MajorBadge
