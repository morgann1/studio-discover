--!strict

export type Dependency = {
	read scope: string,
	read name: string,
	-- The range as written, such as "^1.2.0".
	read range: string,
	-- The first version number in the range, which the dependency's page preselects.
	read version: string?,
}

--[[
	Splits a manifest's "scope/name@range" into its parts, or returns nil when it
		doesn't have that shape.
]]
const function parseDependency(spec: string): Dependency?
	const scope, name, range = string.match(spec, "^([^/@]+)/([^/@]+)@(.+)$")
	if scope == nil or name == nil or range == nil then
		return nil
	end

	return {
		scope = scope,
		name = name,
		range = range,
		version = string.match(range, "%d+%.%d+%.%d+"),
	}
end

return parseDependency
