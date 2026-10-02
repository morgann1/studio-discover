--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const types = require(StudioDiscover.PesdeRegistry.types)

--[[
	The id resolve keys a pesde package by. It carries a target as well as a
		version, because the same package can be published for roblox and
		roblox_server and the two resolve independently.
]]
const function formatPackageId(scope: string, name: string, version: string, target: types.Target): string
	return `{scope}/{name}@{version} {target}`
end

return formatPackageId
