--!strict

const json = require("@std/json")

const decodeLuauTask = require("@scripts/lib/luau-execution/decodeLuauTask")
const fetchAsync = require("@scripts/lib/fetchAsync")

export type Options = {
	read universeId: string,
	read placeId: string,
	read apiKey: string,
	read script: string,
	read timeoutSeconds: number,
	-- A path from `uploadBinaryInputAsync`, which the script reads as `(...).BinaryInput`.
	read binaryInput: string?,
}

-- Starts a Luau Execution task against the latest version of the place.
const function createLuauTaskAsync(options: Options): decodeLuauTask.LuauTask
	const placePath = `universes/{options.universeId}/places/{options.placeId}`

	const response = fetchAsync(`https://apis.roblox.com/cloud/v2/{placePath}/luau-execution-session-tasks`, {
		method = "POST",
		headers = {
			["Content-Type"] = "application/json",
			["x-api-key"] = options.apiKey,
		},
		body = json.serialize({
			script = options.script,
			timeout = `{options.timeoutSeconds}s`,
			binaryInput = options.binaryInput,
		}),
	})

	return decodeLuauTask(response.body)
end

return createLuauTaskAsync
