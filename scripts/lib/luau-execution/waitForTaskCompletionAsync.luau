--!strict

const task = require("@lute/task")

const color = require("@scripts/lib/color")
const decodeLuauTask = require("@scripts/lib/luau-execution/decodeLuauTask")
const fetchAsync = require("@scripts/lib/fetchAsync")

const POLL_INTERVAL_SECONDS = 2
const RETRY_DELAY_SECONDS = 5

--[[
	Polling only reads a task Roblox is already running, so a failed poll can always
		be repeated. One connection blip should not abandon a healthy task, but a
		sustained outage still fails.
]]
const MAX_CONSECUTIVE_FAILURES = 5

--[[
	Polls a task until it leaves the queue and finishes, and returns its final state.
		Roblox enforces the task's own timeout, so this always ends.
]]
const function waitForTaskCompletionAsync(taskPath: string, apiKey: string): decodeLuauTask.LuauTask
	const url = `https://apis.roblox.com/cloud/v2/{taskPath}`
	local consecutiveFailures = 0

	while true do
		-- Through a closure, so the options are still checked against fetchAsync's types.
		const ok, result = pcall(function()
			return fetchAsync(url, {
				headers = { ["x-api-key"] = apiKey },
			})
		end)

		if not ok then
			consecutiveFailures += 1
			if consecutiveFailures >= MAX_CONSECUTIVE_FAILURES then
				error(`Gave up polling {url} after {consecutiveFailures} failures: {result}`, 0)
			end

			print(color.yellow(`Polling failed ({consecutiveFailures}/{MAX_CONSECUTIVE_FAILURES}): {result}`))
			task.wait(RETRY_DELAY_SECONDS)
			continue
		end

		consecutiveFailures = 0

		const luauTask = decodeLuauTask(result.body)
		if luauTask.state ~= "QUEUED" and luauTask.state ~= "PROCESSING" then
			return luauTask
		end

		task.wait(POLL_INTERVAL_SECONDS)
	end
end

return waitForTaskCompletionAsync
