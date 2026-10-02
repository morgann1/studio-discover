--!strict

local json = require("@std/json")

local fetch = require("@scripts/lib/fetch")
local types = require("./types")

type TaskLogsResponse = {
	luauExecutionSessionTaskLogs: { { structuredMessages: { types.StructuredLog }? } },
}

-- Returns what the task printed, warned, and errored, in order.
local function getLuauTaskLogsAsync(taskPath: string, apiKey: string): { types.StructuredLog }
	local response = fetch(`https://apis.roblox.com/cloud/v2/{taskPath}/logs?view=STRUCTURED`, {
		headers = { ["x-api-key"] = apiKey },
	})

	local logs: TaskLogsResponse = json.deserialize(response.body) :: any

	local page = logs.luauExecutionSessionTaskLogs[1]
	if page == nil or page.structuredMessages == nil then
		return {}
	end

	return page.structuredMessages
end

return getLuauTaskLogsAsync
