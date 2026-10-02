--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const coreTypes = require(StudioDiscover.Libraries.Core.types)

--[[
	Describes the roots a resolve could not place, or returns nil when it placed
		them all. Applying without a root uninstalls it, so every installer operation
		stops on this instead of applying.
]]
const function unresolvedRootsError(unresolved: { coreTypes.RootRequest }, failures: { string }): string?
	if #unresolved == 0 then
		return nil
	end

	const names: { string } = {}
	for _, root in unresolved do
		table.insert(names, `{root.scope}/{root.name}@{root.version}`)
	end

	const message = `Failed to resolve {table.concat(names, ", ")}`
	return if #failures > 0 then `{message} ({table.concat(failures, "; ")})` else message
end

return unresolvedRootsError
