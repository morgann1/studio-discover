local Discover = script:FindFirstAncestor("Discover")

local Settings = require(Discover.Src.UI.Settings)

local function splitWords(raw: string): { string }
	local words = {}
	for word in string.gmatch(raw, "[^-_%s]+") do
		table.insert(words, word)
	end
	return words
end

local function capitalize(word: string): string
	if word == "" then
		return word
	end
	return string.upper(string.sub(word, 1, 1)) .. string.sub(word, 2)
end

local function formatPackageName(raw: string, convention: Settings.NamingConvention): string
	if convention == "As-Is" then
		return raw
	end

	local words = splitWords(raw)
	if #words == 0 then
		return raw
	end

	local lowered = table.create(#words)
	for index, word in words do
		lowered[index] = string.lower(word)
	end

	if convention == "PascalCase" then
		local parts = table.create(#lowered)
		for index, word in lowered do
			parts[index] = capitalize(word)
		end
		return table.concat(parts, "")
	elseif convention == "camelCase" then
		local parts = table.create(#lowered)
		parts[1] = lowered[1]
		for index = 2, #lowered do
			parts[index] = capitalize(lowered[index])
		end
		return table.concat(parts, "")
	elseif convention == "snake_case" then
		return table.concat(lowered, "_")
	elseif convention == "kebab-case" then
		return table.concat(lowered, "-")
	end

	return raw
end

return formatPackageName
