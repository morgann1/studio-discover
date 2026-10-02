--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const trim = require(StudioDiscover.Core.trim)

export type TomlTable = { [string]: unknown }

-- Splits `a."b.c".d` into its keys, honoring quoted keys that contain dots and ignoring spaces around the dots.
const function splitTablePath(path: string): { string }
	const parts: { string } = {}
	local index = 1

	while index <= #path do
		const symbol = string.sub(path, index, index)
		if symbol == "." then
			index += 1
		elseif symbol == '"' or symbol == "'" then
			const closeIndex = string.find(path, symbol, index + 1, true) or #path + 1
			table.insert(parts, string.sub(path, index + 1, closeIndex - 1))
			index = closeIndex + 1
		else
			const nextSpecial = string.find(path, "[.\"']", index)
			const segmentEnd = if nextSpecial ~= nil then nextSpecial - 1 else #path
			const segment = trim(string.sub(path, index, segmentEnd))
			if segment ~= "" then
				table.insert(parts, segment)
			end
			index = segmentEnd + 1
		end
	end

	return parts
end

-- Walks the first `depth` keys of `parts` down from `root`, creating tables that do not exist yet.
const function ensurePath(root: TomlTable, parts: { string }, depth: number): TomlTable
	local current = root

	for index = 1, depth do
		const key = parts[index]
		const existing = current[key]
		if existing == nil then
			const created: TomlTable = {}
			current[key] = created
			current = created
		elseif typeof(existing) == "table" then
			current = existing :: TomlTable
		else
			error(`TOML key "{key}" is not a table`)
		end
	end

	return current
end

-- Splits an array's inner text at the commas that are not inside a string or a nested array.
const function splitTopLevelCommas(inner: string): { string }
	const items: { string } = {}
	local depth = 0
	local inQuote: string? = nil
	local start = 1
	local index = 1

	while index <= #inner do
		const char = string.sub(inner, index, index)
		if inQuote ~= nil then
			-- Only a basic string has escapes; a literal one ends at the next quote.
			if inQuote == '"' and char == "\\" then
				index += 2
				continue
			elseif char == inQuote then
				inQuote = nil
			end
		elseif char == '"' or char == "'" then
			inQuote = char
		elseif char == "[" then
			depth += 1
		elseif char == "]" then
			depth -= 1
		elseif char == "," and depth == 0 then
			table.insert(items, string.sub(inner, start, index - 1))
			start = index + 1
		end

		index += 1
	end

	const trailing = string.sub(inner, start)
	if string.match(trailing, "%S") ~= nil then
		table.insert(items, trailing)
	end

	return items
end

-- Creates the array a `[[path]]` header appends to, the first time that header appears.
const function addArrayTable(root: TomlTable, path: string): { TomlTable }
	const parts = splitTablePath(path)
	const parent = ensurePath(root, parts, #parts - 1)

	const entries: { TomlTable } = {}
	parent[parts[#parts]] = entries
	return entries
end

const ESCAPES: { [string]: string? } = {
	["\\"] = "\\",
	['"'] = '"',
	["n"] = "\n",
	["t"] = "\t",
	["r"] = "\r",
}
table.freeze(ESCAPES)

-- Undoes the escapes in a basic string's text in one pass, so an escaped backslash never starts another escape.
const function unescape(text: string): string
	return (string.gsub(text, "\\(.)", function(char: string): string
		return ESCAPES[char] or `\\{char}`
	end))
end

-- Drops a `#` comment from a line, ignoring any `#` inside a string.
const function stripComment(line: string): string
	local quote: string? = nil
	local index = 1

	while index <= #line do
		const char = string.sub(line, index, index)
		if quote == '"' and char == "\\" then
			index += 2
			continue
		elseif quote ~= nil then
			if char == quote then
				quote = nil
			end
		elseif char == '"' or char == "'" then
			quote = char
		elseif char == "#" then
			return string.sub(line, 1, index - 1)
		end

		index += 1
	end

	return line
end

const function parseValue(rawText: string): unknown
	const text = trim(rawText)

	-- A literal string keeps its text as written; a basic string has escapes.
	if string.match(text, '^"(.*)"$') ~= nil then
		return unescape(string.sub(text, 2, -2))
	elseif string.match(text, "^'(.*)'$") ~= nil then
		return string.sub(text, 2, -2)
	end

	const number = tonumber(text)
	if number ~= nil then
		return number
	end

	if text == "true" then
		return true
	elseif text == "false" then
		return false
	elseif text == "inf" or text == "+inf" then
		return math.huge
	elseif text == "-inf" then
		return -math.huge
	elseif text == "nan" then
		return 0 / 0
	elseif string.sub(text, 1, 1) == "[" and string.sub(text, -1) == "]" then
		const items: { unknown } = {}
		for _, item in splitTopLevelCommas(string.sub(text, 2, -2)) do
			table.insert(items, parseValue(item))
		end

		return items
	end

	return text
end

--[[
	Reads the TOML that package manifests use: tables and arrays of tables with
		dotted or quoted headers, and string, number, boolean, and array values.

	It reads one line at a time, so a value cannot span lines, and an inline table
		comes back as its raw text. A `#` comment ends a line anywhere outside a
		string.
]]
const function parseToml(input: string): TomlTable
	const normalized = string.gsub(input, "\r\n?", "\n")

	const result: TomlTable = {}
	const arrayTables: { [string]: { TomlTable }? } = {}
	local currentTable = result

	for _, rawLine in string.split(normalized, "\n") do
		const line = trim(stripComment(rawLine))
		if line == "" then
			continue
		end

		const arrayTablePath = string.match(line, "^%[%[(.-)%]%]$")
		if arrayTablePath ~= nil then
			const entries = arrayTables[arrayTablePath] or addArrayTable(result, arrayTablePath)
			arrayTables[arrayTablePath] = entries

			const entry: TomlTable = {}
			table.insert(entries, entry)
			currentTable = entry
			continue
		end

		const tablePath = string.match(line, "^%[(.-)%]$")
		if tablePath ~= nil then
			const parts = splitTablePath(tablePath)
			currentTable = ensurePath(result, parts, #parts)
			continue
		end

		const rawKey, rawValue = string.match(line, "^(.-)%s*=%s*(.-)$")
		if rawKey == nil or rawValue == nil then
			continue
		end

		local key = trim(rawKey)
		if string.match(key, '^"(.*)"$') ~= nil or string.match(key, "^'(.*)'$") ~= nil then
			key = string.sub(key, 2, -2)
		end

		currentTable[key] = parseValue(rawValue)
	end

	return result
end

return parseToml
