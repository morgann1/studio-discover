--[[
	Small React helpers ported from https://blog.boyned.com/articles/things-i-learned-using-react/
]]

local React = {}

--[[
	Returns a function that yields an incrementing layout order on each call.
	Lets you reorder children without renumbering every LayoutOrder by hand.
]]
function React.createNextOrder(): () -> number
	local order = 0
	return function()
		order += 1
		return order
	end
end

--[[
	Returns a function that produces a unique name given a base. Repeated
	calls with the same base disambiguate by appending "_2", "_3", etc.
	Useful for dynamic child keys where the input may contain duplicates.
]]
function React.createUniqueKey(): (string) -> string
	local names: { [string]: number } = {}
	return function(name: string): string
		if names[name] == nil then
			names[name] = 1
			return name
		end
		while true do
			names[name] += 1
			local finalName = `{name}_{names[name]}`
			if names[finalName] == nil then
				return finalName
			end
		end
	end
end

return React
