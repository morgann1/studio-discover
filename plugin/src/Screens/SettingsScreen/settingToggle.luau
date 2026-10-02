--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const Toggle = Foundation.Toggle
const InputSize = Foundation.Enums.InputSize

const e = React.createElement

-- A toggle for a `Setting` row's control.
const function settingToggle(value: boolean, onChange: (value: boolean) -> ()): React.Node
	return e(Toggle, {
		isChecked = value,
		onActivated = onChange,
		size = InputSize.Small,
	})
end

return settingToggle
