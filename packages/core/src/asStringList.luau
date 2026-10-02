--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const asTable = require(StudioDiscover.Libraries.Core.asTable)

-- Reads the strings out of a decoded array, skipping anything else. Anything but a table reads as empty.
const function asStringList(value: unknown): { string }
	const strings: { string } = {}
	for _, item in asTable(value) or {} do
		if typeof(item) == "string" then
			table.insert(strings, item)
		end
	end

	return strings
end

return asStringList
