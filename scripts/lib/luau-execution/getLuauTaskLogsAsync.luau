--!strict

const json = require("@std/json")

const fetchAsync = require("@scripts/lib/fetchAsync")
const readJsonField = require("@scripts/lib/readJsonField")

export type MessageType = "MESSAGE_TYPE_UNSPECIFIED" | "OUTPUT" | "INFO" | "WARNING" | "ERROR"

export type StructuredLog = {
	read message: string,
	read messageType: MessageType,
}

const MESSAGE_TYPES: { [string]: MessageType? } = {
	MESSAGE_TYPE_UNSPECIFIED = "MESSAGE_TYPE_UNSPECIFIED",
	OUTPUT = "OUTPUT",
	INFO = "INFO",
	WARNING = "WARNING",
	ERROR = "ERROR",
}

table.freeze(MESSAGE_TYPES)

-- Returns what the task printed, warned, and errored, in order.
const function getLuauTaskLogsAsync(taskPath: string, apiKey: string): { StructuredLog }
	const response = fetchAsync(`https://apis.roblox.com/cloud/v2/{taskPath}/logs?view=STRUCTURED`, {
		headers = { ["x-api-key"] = apiKey },
	})

	const logs: { StructuredLog } = {}

	const pages = readJsonField(json.deserialize(response.body), "luauExecutionSessionTaskLogs")
	if typeof(pages) ~= "table" then
		return logs
	end

	for _, page in pages do
		const entries = readJsonField(page, "structuredMessages")
		if typeof(entries) ~= "table" then
			continue
		end

		for _, entry in entries do
			const message = readJsonField(entry, "message")
			if typeof(message) ~= "string" then
				continue
			end

			-- A message type Roblox adds later still prints, just without a color.
			const rawType = readJsonField(entry, "messageType")
			const knownType = if typeof(rawType) == "string" then MESSAGE_TYPES[rawType] else nil
			const messageType: MessageType = knownType or "MESSAGE_TYPE_UNSPECIFIED"

			table.insert(logs, { message = message, messageType = messageType })
		end
	end

	return logs
end

return getLuauTaskLogsAsync
