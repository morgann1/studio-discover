--[[
	Returns a closure that yields a unique string key each call, so React
	children built from a user-supplied name stay stable even when two
	items would otherwise collide. The first time a name is seen it's
	returned unchanged; subsequent collisions get a `_2`, `_3`, ... suffix.
]]
local function createUniqueKey(): (string) -> string
	local names: { [string]: number } = {}
	return function(name: string): string
		if names[name] == nil then
			names[name] = 1
			return name
		end
		while true do
			names[name] += 1
			local uniqueName = `{name}_{names[name]}`
			if names[uniqueName] == nil then
				return uniqueName
			end
		end
	end
end

return createUniqueKey
