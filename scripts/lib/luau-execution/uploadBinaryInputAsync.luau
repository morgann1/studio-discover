--!strict

local json = require("@std/json")

local fetch = require("@scripts/lib/fetch")

type BinaryInputResponse = {
	path: string,
	uploadUri: string,
}

--[[
	Uploads `contents` as a binary input for a Luau Execution task, and returns the
		path to pass as `createLuauTaskAsync`'s `binaryInput`.
]]
local function uploadBinaryInputAsync(universeId: string, apiKey: string, contents: string): string
	local created =
		fetch(`https://apis.roblox.com/cloud/v2/universes/{universeId}/luau-execution-session-task-binary-inputs`, {
			method = "POST",
			headers = {
				["Content-Type"] = "application/json",
				["x-api-key"] = apiKey,
			},
			body = json.serialize({ size = #contents }),
		})

	local binaryInput: BinaryInputResponse = json.deserialize(created.body) :: any

	fetch(binaryInput.uploadUri, {
		method = "PUT",
		headers = {
			["Content-Type"] = "application/octet-stream",
			["x-api-key"] = apiKey,
		},
		body = contents,
	})

	return binaryInput.path
end

return uploadBinaryInputAsync
