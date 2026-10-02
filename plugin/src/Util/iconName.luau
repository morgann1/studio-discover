--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)

const IconName = Foundation.Enums.IconName

--[[
	Returns the glyph for an icon, as in `iconName("Sidebar")`. Foundation's
		`IconName` table types as an error under the new solver, which breaks prop
		inference for components that take an icon. This checks the name and gives a
		plain string back.
]]
const function iconName(name: Foundation.IconName): string
	return IconName[name]
end

return iconName
