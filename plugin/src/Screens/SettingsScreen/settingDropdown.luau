--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const Dropdown = Foundation.Dropdown
const InputSize = Foundation.Enums.InputSize

const e = React.createElement

--[[
	A dropdown for a `Setting` row's control. Each option is shown as its own text,
		and `onChange` receives the option itself rather than the dropdown's string id.
]]
const function settingDropdown<T>(value: T, options: { T }, onChange: (value: T) -> ()): React.Node
	const items: { Foundation.DropdownItem } = {}
	for _, option in options do
		table.insert(items, { id = tostring(option), text = tostring(option) })
	end

	return e(Dropdown.Root, {
		label = "",
		value = tostring(value),
		items = items,
		onItemChanged = function(id: string)
			for _, option in options do
				if tostring(option) == id then
					onChange(option)
					return
				end
			end
		end,
		size = InputSize.Small,
		width = UDim.new(0, 200),
	})
end

return settingDropdown
