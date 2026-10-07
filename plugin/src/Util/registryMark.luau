--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const types = require(StudioDiscover.Libraries.Core.types)

-- Each registry's favicon, from its own site. Nevermore's is the logo from its repo.
const MARKS: { [types.Registry]: string } = {
	wally = "rbxassetid://84745302108730",
	pesde = "rbxassetid://107553028826404",
	nevermore = "rbxassetid://88456073638503",
}

-- Returns the square mark drawn wherever a registry is named.
const function registryMark(registry: types.Registry): string
	return MARKS[registry]
end

return registryMark
