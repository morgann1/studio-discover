--!strict

export type TarEntry = {
	path: string,
	kind: "file" | "directory",
	content: string,
}

local BLOCK = 512

local function readString(data: string, offset: number, length: number): string
	local s = string.sub(data, offset + 1, offset + length)
	local nul = string.find(s, "\0", 1, true)
	if nul ~= nil then
		return string.sub(s, 1, nul - 1)
	end
	return s
end

local function readOctal(data: string, offset: number, length: number): number
	local s = readString(data, offset, length):gsub("%s+$", "")
	if s == "" then
		return 0
	end
	return tonumber(s, 8) or 0
end

local function isAllZero(data: string, offset: number): boolean
	for i = 1, BLOCK do
		if string.byte(data, offset + i) ~= 0 then
			return false
		end
	end
	return true
end

local function parseTar(data: string): { TarEntry }
	local entries: { TarEntry } = {}
	local cursor = 0
	local total = #data

	while cursor + BLOCK <= total do
		if isAllZero(data, cursor) then
			break
		end

		local name = readString(data, cursor, 100)
		local size = readOctal(data, cursor + 124, 12)
		local typeflag = string.sub(data, cursor + 156, cursor + 156)
		local prefix = readString(data, cursor + 345, 155)

		if prefix ~= "" then
			name = `{prefix}/{name}`
		end

		cursor += BLOCK
		local content = string.sub(data, cursor + 1, cursor + size)
		cursor += math.ceil(size / BLOCK) * BLOCK

		local isDir = typeflag == "5" or string.sub(name, -1) == "/"
		local isSkip = typeflag == "x"
			or typeflag == "g"
			or typeflag == "L"
			or typeflag == "K"
			or typeflag == "1"
			or typeflag == "2"
			or typeflag == "3"
			or typeflag == "4"
			or typeflag == "6"

		if isDir then
			table.insert(entries, { path = name, kind = "directory", content = "" })
		elseif not isSkip then
			table.insert(entries, { path = name, kind = "file", content = content })
		end
	end

	return entries
end

return table.freeze({
	parse = parseTar,
})
