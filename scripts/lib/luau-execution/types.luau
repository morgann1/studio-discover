--!strict

export type TaskState = "STATE_UNSPECIFIED" | "QUEUED" | "PROCESSING" | "CANCELLED" | "COMPLETE" | "FAILED"

-- `output` and `error` are mutually exclusive, and only appear once the task has finished.
export type LuauTask = {
	path: string,
	state: TaskState,
	output: { results: { unknown } }?,
	error: { code: string, message: string }?,
}

export type StructuredLog = {
	message: string,
	messageType: "MESSAGE_TYPE_UNSPECIFIED" | "OUTPUT" | "INFO" | "WARNING" | "ERROR",
}

return {}
