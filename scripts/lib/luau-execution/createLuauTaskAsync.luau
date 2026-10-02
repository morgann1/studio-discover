--!strict

local json = require("@std/json")

local fetch = require("@scripts/lib/fetch")
local types = require("./types")

export type Options = {
	universeId: string,
	placeId: string,
	apiKey: string,
	script: string,
	timeoutSeconds: number,
	-- A path from `uploadBinaryInputAsync`, which the script reads as `(...).BinaryInput`.
	binaryInput: string?,
}

-- Starts a Luau Execution task against the latest version of the place.
local function createLuauTaskAsync(options: Options): types.LuauTask
	local response = fetch(
		`https://apis.roblox.com/cloud/v2/universes/{options.universeId}/places/{options.placeId}/luau-execution-session-tasks`,
		{
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
		}
	)

	return json.deserialize(response.body) :: any
end

return createLuauTaskAsync
