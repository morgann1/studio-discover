--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const Alert = Foundation.Alert
const View = Foundation.View
const AlertSeverity = Foundation.Enums.AlertSeverity
const AlertVariant = Foundation.Enums.AlertVariant

const e = React.createElement

-- Why a screen's data failed to load, at the top of its body.
const function LoadError(props: {
	read text: string,
})
	return e(View, {
		tag = "size-full-0 auto-y padding-x-large padding-bottom-medium",
	}, {
		Alert = e(Alert, {
			variant = AlertVariant.Feedback,
			severity = AlertSeverity.Error,
			text = props.text,
		}),
	})
end

return LoadError
