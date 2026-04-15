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
