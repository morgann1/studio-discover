--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const asTable = require(StudioDiscover.Libraries.Core.asTable)

--[[
	Reads the string-to-string pairs out of a decoded object, skipping anything
		else. Anything but a table reads as empty.
]]
const function asStringMap(value: unknown): { [string]: string }
	const map: { [string]: string } = {}
	for key, item in asTable(value) or {} do
		if typeof(key) == "string" and typeof(item) == "string" then
			map[key] = item
		end
	end

	return map
end

return asStringMap
