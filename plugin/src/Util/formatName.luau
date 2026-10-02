--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const capitalize = require(StudioDiscover.Source.Util.capitalize)

-- Splits a name into lowercase words at dashes, underscores, and lower-to-upper case changes.
const function tokenize(name: string): { string }
	const tokens: { string } = {}

	for part in string.gmatch(name, "[^-_]+") do
		local current = ""

		for i = 1, #part do
			const character = string.sub(part, i, i)
			const previous = string.sub(part, i - 1, i - 1)

			if i > 1 and string.match(character, "%u") ~= nil and string.match(previous, "%l") ~= nil then
				table.insert(tokens, string.lower(current))
				current = character
			else
				current ..= character
			end
		end

		if current ~= "" then
			table.insert(tokens, string.lower(current))
		end
	end

	return tokens
end

--[[
	Rewrites a package name in a naming convention, such as "PascalCase".
		"Original" returns the name unchanged.
]]
const function formatName(name: string, convention: string): string
	if convention == "Original" then
		return name
	end

	const tokens = tokenize(name)

	if convention == "PascalCase" then
		const parts: { string } = {}
		for _, token in tokens do
			table.insert(parts, capitalize(token))
		end

		return table.concat(parts)
	elseif convention == "camelCase" then
		const parts: { string } = {}
		for i, token in tokens do
			parts[i] = if i == 1 then token else capitalize(token)
		end

		return table.concat(parts)
	elseif convention == "snake_case" then
		return table.concat(tokens, "_")
	elseif convention == "kebab-case" then
		return table.concat(tokens, "-")
	end

	return name
end

return formatName
