--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local capitalize = require(StudioDiscover.Source.Util.capitalize)

local function tokenize(name: string): { string }
	local tokens: { string } = {}

	for part in name:gmatch("[^-_]+") do
		local current = ""
		for i = 1, #part do
			local ch = part:sub(i, i)
			local prev = if i > 1 then part:sub(i - 1, i - 1) else ""
			if i > 1 and ch:match("%u") ~= nil and prev:match("%l") ~= nil then
				table.insert(tokens, current)
				current = ch
			else
				current = current .. ch
			end
		end
		if current ~= "" then
			table.insert(tokens, current)
		end
	end

	for i, token in tokens do
		tokens[i] = token:lower()
	end

	return tokens
end

local function formatName(name: string, convention: string): string
	if convention == "Original" then
		return name
	end

	local tokens = tokenize(name)

	if convention == "PascalCase" then
		local parts: { string } = {}
		for _, token in tokens do
			table.insert(parts, capitalize(token))
		end
		return table.concat(parts, "")
	elseif convention == "camelCase" then
		local parts: { string } = {}
		for i, token in tokens do
			parts[i] = if i == 1 then token else capitalize(token)
		end
		return table.concat(parts, "")
	elseif convention == "snake_case" then
		return table.concat(tokens, "_")
	elseif convention == "kebab-case" then
		return table.concat(tokens, "-")
	end

	return name
end

return formatName
