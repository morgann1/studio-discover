--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const types = require(StudioDiscover.Libraries.Core.types)

-- Each registry's favicon, from its own site.
const MARKS: { [types.Registry]: string } = {
	wally = "rbxassetid://84745302108730",
	pesde = "rbxassetid://107553028826404",
}

-- Returns the square mark drawn wherever a registry is named.
const function registryMark(registry: types.Registry): string
	return MARKS[registry]
end

return registryMark
