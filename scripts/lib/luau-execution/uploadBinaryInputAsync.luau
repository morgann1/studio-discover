--!strict

const json = require("@std/json")

const fetchAsync = require("@scripts/lib/fetchAsync")
const readJsonField = require("@scripts/lib/readJsonField")

--[[
	Uploads `contents` as a binary input for a Luau Execution task, and returns the
		path to pass as `createLuauTaskAsync`'s `binaryInput`.
]]
const function uploadBinaryInputAsync(universeId: string, apiKey: string, contents: string): string
	const created = fetchAsync(
		`https://apis.roblox.com/cloud/v2/universes/{universeId}/luau-execution-session-task-binary-inputs`,
		{
			method = "POST",
			headers = {
				["Content-Type"] = "application/json",
				["x-api-key"] = apiKey,
			},
			body = json.serialize({ size = #contents }),
		}
	)

	const binaryInput = json.deserialize(created.body)

	const path = readJsonField(binaryInput, "path")
	assert(typeof(path) == "string", "Expected the binary input to have a path")

	const uploadUri = readJsonField(binaryInput, "uploadUri")
	assert(typeof(uploadUri) == "string", "Expected the binary input to have an upload URI")

	fetchAsync(uploadUri, {
		method = "PUT",
		headers = {
			["Content-Type"] = "application/octet-stream",
			["x-api-key"] = apiKey,
		},
		body = contents,
	})

	return path
end

return uploadBinaryInputAsync
