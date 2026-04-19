--!strict

local function createUniqueKey(): (string) -> string
	local names = {}
	return function(name)
		if names[name] == nil then
			names[name] = 1
			return name
		else
			while true do
				names[name] += 1
				local finalName = `{name}_{names[name]}`

				if names[finalName] == nil then
					return finalName
				end
			end
		end
	end
end

return createUniqueKey
