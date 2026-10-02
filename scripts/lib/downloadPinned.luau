--!strict

local crypto = require("@lute/crypto")
local fs = require("@std/fs")
local net = require("@lute/net")

local color = require("@scripts/lib/color")

local function sha256(contents: string): string
	local digest = crypto.digest(crypto.hash.sha256, contents)

	local hex = table.create(buffer.len(digest))
	for index = 0, buffer.len(digest) - 1 do
		table.insert(hex, string.format("%02x", buffer.readu8(digest, index)))
	end

	return table.concat(hex)
end

--[[
	Downloads `url` to `destination` and errors unless its SHA-256 matches. A file
		already at `destination` with the right hash is kept, so repeat runs stay offline.
]]
local function downloadPinned(url: string, destination: string, expectedSha256: string)
	if fs.exists(destination) and sha256(fs.readFileToString(destination)) == expectedSha256 then
		return
	end

	print(color.bold(`> download {url}`))

	local response = net.client.request(url)
	if not response.ok then
		error(`Failed to download {url}: HTTP {response.status}`, 0)
	end

	local actual = sha256(response.body)
	if actual ~= expectedSha256 then
		error(`Checksum mismatch for {url}\nexpected {expectedSha256}\nactual   {actual}`, 0)
	end

	fs.writeStringToFile(destination, response.body)
end

return downloadPinned
