--!strict

local toml = {}

type SerializerState = {
	buf: buffer,
	cursor: number,
}

local serializeArray

local function serializeValue(value: string | number | boolean): string
	if typeof(value) == "string" then
		value = string.gsub(value, "\\", "\\\\")
		value = string.gsub(value, "\n", "\\n")
		value = string.gsub(value, "\t", "\\t")
		return '"' .. value .. '"'
	elseif typeof(value) == "boolean" then
		return if value then "true" else "false"
	elseif value == math.huge then
		return "inf"
	elseif value == -math.huge then
		return "-inf"
	elseif value ~= value then
		return "nan"
	else
		return tostring(value)
	end
end

function serializeArray(arr: { any }): string
	local parts: { string } = {}
	for _, v in arr do
		if typeof(v) == "table" then
			table.insert(parts, serializeArray(v))
		else
			table.insert(parts, serializeValue(v))
		end
	end
	return "[" .. table.concat(parts, ", ") .. "]"
end

local function quoteKey(key: string): string
	if not string.match(key, "^[%w_-]+$") then
		return '"' .. key .. '"'
	end
	return key
end

local function tableToToml(tbl: { [any]: any }, parent: string?): string
	local directs: { [any]: any } = {}
	local subtables: { [any]: any } = {}
	local arrayTables: { [any]: any } = {}

	for k, v in tbl do
		if typeof(v) == "table" and next(v) ~= nil then
			if #v > 0 then
				if typeof(v[1]) == "table" then
					arrayTables[k] = v
				else
					directs[k] = v
				end
			else
				subtables[k] = v
			end
		else
			directs[k] = v
		end
	end

	local result = ""

	if parent ~= nil and next(directs) ~= nil then
		result ..= "\n[" .. parent .. "]\n"
	end

	for k, v in directs do
		if typeof(v) == "table" then
			result ..= quoteKey(k) .. " = " .. serializeArray(v) .. "\n"
		else
			result ..= quoteKey(k) .. " = " .. serializeValue(v) .. "\n"
		end
	end

	for k, v in subtables do
		local key = parent and (parent .. "." .. quoteKey(k)) or quoteKey(k)
		result ..= tableToToml(v, key)
	end

	for k, v in arrayTables do
		for _, entry in v do
			result ..= "\n[[" .. (parent and parent .. "." or "") .. quoteKey(k) .. "]]\n"
			result ..= tableToToml(entry, nil)
		end
	end

	return result
end

local function serialize(tbl: { [any]: any }): string
	return tableToToml(tbl, nil)
end

type DeserializerState = {
	buf: string,
	cursor: number,
}

local function splitTablePath(path: string): { string }
	local parts = {}
	local index = 1
	local pathLen = string.len(path)

	while index <= pathLen do
		local symbol = string.sub(path, index, index)
		if symbol == "." then
			index += 1
		elseif symbol == '"' or symbol == "'" then
			local closePos = string.find(path, symbol, index + 1, true) or pathLen + 1
			table.insert(parts, string.sub(path, index + 1, closePos - 1))
			index = closePos + 1
		else
			local nextSpecial = string.find(path, "[.\"']", index)
			local segEnd = if nextSpecial then nextSpecial - 1 else pathLen
			table.insert(parts, string.sub(path, index, segEnd))
			index = segEnd + 1
		end
	end

	return parts
end

local function ensurePath(root: { [string]: unknown }, parts: { string }, depth: number?): { [string]: unknown }
	local current = root
	for i = 1, depth or #parts do
		if not current[parts[i]] then
			current[parts[i]] = {}
		end
		current = current[parts[i]] :: { [string]: unknown }
	end
	return current
end

local function skipWhitespace(state: DeserializerState): ()
	local pos = state.cursor
	while pos <= string.len(state.buf) and string.match(string.sub(state.buf, pos, pos), "%s") do
		pos += 1
	end
	state.cursor = pos
end

local function readLine(state: DeserializerState): string
	local nextLine = string.find(state.buf, "\n", state.cursor) or string.len(state.buf) + 1
	local line = string.sub(state.buf, state.cursor, nextLine - 1)
	state.cursor = nextLine + 1
	return line
end

local function splitTopLevelCommas(inner: string): { string }
	local items: { string } = {}
	local depth = 0
	local inQuote: string? = nil
	local start = 1
	local len = string.len(inner)
	local i = 1
	while i <= len do
		local ch = string.sub(inner, i, i)
		if inQuote ~= nil then
			if ch == "\\" then
				i += 2
				continue
			elseif ch == inQuote then
				inQuote = nil
			end
		elseif ch == '"' or ch == "'" then
			inQuote = ch
		elseif ch == "[" then
			depth += 1
		elseif ch == "]" then
			depth -= 1
		elseif ch == "," and depth == 0 then
			table.insert(items, string.sub(inner, start, i - 1))
			start = i + 1
		end
		i += 1
	end
	local trailing = string.sub(inner, start)
	if string.match(trailing, "%S") then
		table.insert(items, trailing)
	end
	return items
end

local parseScalar
local parseArray

function parseArray(text: string): { any }
	local inner = string.sub(text, 2, -2)
	local items = splitTopLevelCommas(inner)
	local result: { any } = {}
	for _, item in items do
		table.insert(result, parseScalar(item))
	end
	return result
end

function parseScalar(rawText: string): any
	local text = string.match(rawText, "^%s*(.-)%s*$") :: string
	if string.match(text, '^"(.*)"$') or string.match(text, "^'(.*)'$") then
		local unquoted = string.sub(text, 2, -2)
		unquoted = string.gsub(unquoted, "\\\\", "\\")
		unquoted = string.gsub(unquoted, "\\n", "\n")
		unquoted = string.gsub(unquoted, "\\t", "\t")
		return unquoted
	elseif tonumber(text) then
		return tonumber(text)
	elseif text == "true" then
		return true
	elseif text == "false" then
		return false
	elseif text == "inf" or text == "+inf" then
		return math.huge
	elseif text == "-inf" then
		return -math.huge
	elseif text == "nan" then
		return 0 / 0
	elseif string.sub(text, 1, 1) == "[" and string.sub(text, -1, -1) == "]" then
		return parseArray(text)
	else
		return text
	end
end

local function deserialize(input: string): { [string]: unknown }
	input = string.gsub(input, "\r\n", "\n")
	input = string.gsub(input, "\r", "\n")

	local state: DeserializerState = {
		buf = input,
		cursor = 1,
	}
	local result: { [string]: unknown } = {}
	local currentTable = result
	local arrayTables = {}

	while state.cursor <= string.len(state.buf) do
		skipWhitespace(state)
		local line = readLine(state)

		if line == "" or string.sub(line, 1, 1) == "#" then
			continue
		end

		if string.match(line, "^%[%[(.-)%]%]$") then
			local tableName = string.match(line, "^%[%[(.-)%]%]$") or ""

			if not arrayTables[tableName] then
				arrayTables[tableName] = {}
				local parts = splitTablePath(tableName)
				local leaf = parts[#parts]
				local _parent = ensurePath(result, parts, #parts - 1)
				_parent[leaf] = arrayTables[tableName]
			end

			local newEntry = {}
			table.insert(arrayTables[tableName], newEntry)
			currentTable = newEntry
		elseif string.match(line, "^%[(.-)%]$") then
			local tablePath = string.match(line, "^%[(.-)%]$")
			currentTable = ensurePath(result, splitTablePath(tablePath :: string))
		elseif string.match(line, "^(.-)%s*=%s*(.-)$") then
			local rawKey, rawValue = string.match(line, "^(.-)%s*=%s*(.-)$")
			assert(rawKey and rawValue)
			local key = string.match(rawKey, "^%s*(.-)%s*$") :: string
			if string.match(key, '^"(.*)"$') or string.match(key, "^'(.*)'$") then
				key = string.sub(key, 2, -2)
			end
			currentTable[key] = parseScalar(rawValue)
		end
	end

	return result
end

toml.serialize = serialize
toml.deserialize = deserialize

return table.freeze(toml)
