--!strict

export type TarEntry = {
	read path: string,
	read content: string,
}

const BLOCK_SIZE = 512

-- Links, device files, directories, FIFOs, and the metadata headers parseTar does not read carry nothing to install.
const SKIPPED_TYPE_FLAGS: { [string]: true? } = {
	["1"] = true,
	["2"] = true,
	["3"] = true,
	["4"] = true,
	["5"] = true,
	["6"] = true,
	["g"] = true,
	["K"] = true,
}
table.freeze(SKIPPED_TYPE_FLAGS)

const function readString(data: string, offset: number, length: number): string
	const field = string.sub(data, offset + 1, offset + length)
	const nul = string.find(field, "\0", 1, true)
	return if nul ~= nil then string.sub(field, 1, nul - 1) else field
end

const function readOctal(data: string, offset: number, length: number): number
	const field = readString(data, offset, length):gsub("%s+$", "")
	return tonumber(field, 8) or 0
end

const function isZeroBlock(data: string, offset: number): boolean
	for index = 1, BLOCK_SIZE do
		if string.byte(data, offset + index) ~= 0 then
			return false
		end
	end

	return true
end

--[[
	Reads the files in an uncompressed ustar archive, stopping at the first all-zero
		block.

	A path too long for the header arrives in the entry before it: a GNU `L` entry
		holds the whole path, and a pax `x` entry holds it as a `path=` record.
]]
const function parseTar(data: string): { TarEntry }
	const entries: { TarEntry } = {}
	local cursor = 0
	local longPath: string? = nil

	while cursor + BLOCK_SIZE <= #data do
		if isZeroBlock(data, cursor) then
			break
		end

		const name = readString(data, cursor, 100)
		const size = readOctal(data, cursor + 124, 12)
		const typeFlag = string.sub(data, cursor + 157, cursor + 157)
		const prefix = readString(data, cursor + 345, 155)
		const headerPath = if prefix ~= "" then `{prefix}/{name}` else name

		cursor += BLOCK_SIZE
		const content = string.sub(data, cursor + 1, cursor + size)
		cursor += math.ceil(size / BLOCK_SIZE) * BLOCK_SIZE

		if typeFlag == "L" then
			longPath = readString(content, 0, #content)
			continue
		elseif typeFlag == "x" then
			longPath = content:match("%d+ path=([^\n]*)\n") or longPath
			continue
		end

		const path = longPath or headerPath
		longPath = nil

		-- Older archives mark a directory only with a trailing slash.
		if SKIPPED_TYPE_FLAGS[typeFlag] == nil and string.sub(path, -1) ~= "/" then
			table.insert(entries, { path = path, content = content })
		end
	end

	return entries
end

return parseTar
