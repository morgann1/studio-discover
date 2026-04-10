local React = {}

function React.createNextOrder(): () -> number
	local order = 0
	return function()
		order += 1
		return order
	end
end

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
