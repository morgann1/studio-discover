--!strict

const json = require("@std/json")

const readJsonField = require("@scripts/lib/readJsonField")

export type TaskState = "STATE_UNSPECIFIED" | "QUEUED" | "PROCESSING" | "CANCELLED" | "COMPLETE" | "FAILED"

-- `error` only appears once the task has failed.
export type LuauTask = {
	read path: string,
	read state: TaskState,
	read error: { read code: string, read message: string }?,
}

const TASK_STATES: { [string]: TaskState? } = {
	STATE_UNSPECIFIED = "STATE_UNSPECIFIED",
	QUEUED = "QUEUED",
	PROCESSING = "PROCESSING",
	CANCELLED = "CANCELLED",
	COMPLETE = "COMPLETE",
	FAILED = "FAILED",
}

table.freeze(TASK_STATES)

-- Decodes the body of an Open Cloud response that holds one Luau Execution task.
const function decodeLuauTask(body: string): LuauTask
	const value = json.deserialize(body)

	const path = readJsonField(value, "path")
	assert(typeof(path) == "string", "Expected the task to have a path")

	const rawState = readJsonField(value, "state")
	const state = if typeof(rawState) == "string" then TASK_STATES[rawState] else nil
	assert(state ~= nil, "Expected the task to have a known state")

	const rawError = readJsonField(value, "error")
	const code = readJsonField(rawError, "code")
	const message = readJsonField(rawError, "message")

	return {
		path = path,
		state = state,
		error = if typeof(code) == "string" and typeof(message) == "string"
			then { code = code, message = message }
			else nil,
	}
end

return decodeLuauTask
