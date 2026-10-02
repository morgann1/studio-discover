--!strict

--[[
	Returns a function that hands back `name` the first time it sees it, then
		`name_2`, `name_3`, and so on. Create one per render and use it for every
		dynamic child key.
]]
const function createUniqueKey(): (string) -> string
	const counts: { [string]: number? } = {}

	return function(name)
		local count = counts[name]

		if count == nil then
			counts[name] = 1
			return name
		end

		-- Record every key handed out, so a later "Dog_2" can't clash with a generated one.
		while true do
			count += 1
			const key = `{name}_{count}`

			if counts[key] == nil then
				counts[name] = count
				counts[key] = 1
				return key
			end
		end
	end
end

return createUniqueKey
