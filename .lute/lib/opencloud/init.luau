--!strict
--[[
	Open Cloud Luau Execution Task helper.

	Lute port of Dekkonot/opencloud-luau-execute-lune (MIT). Public surface is
	intentionally close to the upstream so that scripts written against the
	Lune helper port with minimal changes.
]]

local net = require("@lute/net/client")
local process = require("@lute/process")
local task = require("@lute/task")

local json = require("./opencloud/json")

local API_KEY_ENV_VAR = "ROBLOX_API_KEY"

local MAX_PAYLOAD_SIZE = 4_000_000 -- 4 MB
local MAX_INPUT_SIZE = 104_857_600 -- 100 MiB
local MAX_EXECUTION_TIME = 300 -- 5 minutes

local MAX_QUERY_YIELD = 16

local BASE_URL = "https://apis.roblox.com/cloud/v2"
local TASK_CREATE_LATEST = `{BASE_URL}/universes/%s/places/%s/luau-execution-session-tasks`
local TASK_CREATE_VERSIONED = `{BASE_URL}/universes/%s/places/%s/versions/%s/luau-execution-session-tasks`
local BINARY_INPUT_CREATE = `{BASE_URL}/universes/%s/luau-execution-session-task-binary-inputs`

local USER_AGENT = "studio-discover/lute-opencloud-execute 1.0.0"
local RATE_LIMIT_HEADER = "x-ratelimit-reset"
local ID_PATTERN = "([%w%-]+)/tasks/([%w%-]+)$"

export type LuauTaskState = "STATE_UNSPECIFIED" | "QUEUED" | "PROCESSING" | "CANCELLED" | "COMPLETE" | "FAILED"

export type MessageType = "MESSAGE_TYPE_UNSPECIFIED" | "OUTPUT" | "INFO" | "WARNING" | "ERROR"

export type StructuredLog = {
	message: string,
	createTime: string,
	messageType: MessageType,
}

export type TaskErrorType =
	"ERROR_CODE_UNSPECIFIED"
	| "SCRIPT_ERROR"
	| "DEADLINE_EXCEEDED"
	| "OUTPUT_SIZE_LIMIT_EXCEEDED"
	| "INTERNAL_ERROR"

export type TaskError = {
	code: TaskErrorType,
	message: string,
}

export type LuauExecutionTask = {
	path: string,
	user: string,
	state: LuauTaskState,
	timeout: string,

	binaryInput: string?,
	enableBinaryOutput: boolean,
	binaryOutputUri: string?,

	createTime: string?,
	updateTime: string?,
	output: { results: { any } }?,
	error: TaskError?,
	script: string?,
}

type InputUploadResponse = {
	path: string,
	size: number,
	uploadUri: string,
}

type TaskLogsResponse = {
	luauExecutionSessionTaskLogs: {
		{
			path: string,
			messages: { string }?,
			structuredMessages: { StructuredLog }?,
		}
	},
	nextPageToken: string?,
}

local api_key_override: string? = nil

local function api_key(): string
	if api_key_override then
		return api_key_override
	end
	local key = process.env[API_KEY_ENV_VAR]
	if not key then
		error(`no Open Cloud API key specified (consider specifying one with the env var {API_KEY_ENV_VAR})`)
	end
	return key
end

local function header_ci(headers: { [string]: string }, name: string): string?
	if headers[name] then
		return headers[name]
	end
	local lower = string.lower(name)
	for k, v in headers do
		if string.lower(k) == lower then
			return v
		end
	end
	return nil
end

local function failure_message(kind: string, response: net.Response): string
	if response.status == 429 then
		local retry = header_ci(response.headers, RATE_LIMIT_HEADER) or "?"
		return `failed to {kind}: HTTP {response.status}, try again in {retry}s`
	end
	return `failed to {kind}: HTTP {response.status}. body from error:\n{response.body}`
end

local function request_json(url: string, method: string, body: string?): any
	local response = net.request(url, {
		method = method,
		body = body,
		headers = {
			["User-Agent"] = USER_AGENT,
			["Content-Type"] = "application/json",
			["X-API-Key"] = api_key(),
		},
	})
	if not response.ok then
		error(failure_message(`{string.lower(method)} {url}`, response))
	end
	return json.decode(response.body)
end

local function upload_input(input: buffer | string, universe_id: string): string
	local input_size = if type(input) == "buffer" then buffer.len(input) else #input
	if input_size > MAX_INPUT_SIZE then
		error(
			`failed to upload input: input is too large (max size is {MAX_INPUT_SIZE} bytes, your data is {input_size} bytes)`
		)
	end

	local create_url = string.format(BINARY_INPUT_CREATE, universe_id)
	local response: InputUploadResponse = request_json(create_url, "POST", json.encode({ size = input_size }))

	local body_str: string = if type(input) == "buffer" then buffer.tostring(input) else input
	local upload = net.request(response.uploadUri, {
		method = "PUT",
		body = body_str,
		headers = {
			["User-Agent"] = USER_AGENT,
			["Content-Type"] = "application/octet-stream",
			["X-API-Key"] = api_key(),
		},
	})
	if not upload.ok then
		error(failure_message("upload input", upload))
	end

	return response.path
end

local function make_task(
	url: string,
	script: string,
	timeout: number,
	enable_binary_output: boolean?,
	binary_input: string?
): LuauExecutionTask
	local request = {
		script = script,
		timeout = `{timeout}s`,
		enableBinaryOutput = enable_binary_output or false,
		binaryInput = binary_input,
	}

	local body = json.encode(request)
	if #body > MAX_PAYLOAD_SIZE then
		error("failed to create task: the final size of the request is too large for Roblox to accept")
	end

	return request_json(url, "POST", body)
end

local function get_logs(task_: LuauExecutionTask, view: "FLAT" | "STRUCTURED"): TaskLogsResponse
	local url = `{BASE_URL}/{task_.path}/logs?view={view}`
	return request_json(url, "GET")
end

local function query_status(task_: LuauExecutionTask): LuauExecutionTask
	return request_json(`{BASE_URL}/{task_.path}`, "GET")
end

local luau_execute = {}

--[[ Creates a LuauExecutionTask on the latest version of the given place. ]]
function luau_execute.create_task_latest(
	universe_id: string,
	place_id: string,
	script: buffer | string,
	timeout: number?,
	enable_binary_output: boolean?,
	binary_input: (buffer | string)?
): LuauExecutionTask
	local t = timeout or MAX_EXECUTION_TIME
	if t < 1 or t > MAX_EXECUTION_TIME then
		error(`specified timeout is outside of acceptable range [1, {MAX_EXECUTION_TIME}]`)
	end

	local script_str: string = if type(script) == "buffer" then buffer.tostring(script) else script

	local input_path: string? = nil
	if binary_input ~= nil then
		input_path = upload_input(binary_input, universe_id)
	end

	return make_task(
		string.format(TASK_CREATE_LATEST, universe_id, place_id),
		script_str,
		t,
		enable_binary_output,
		input_path
	)
end

--[[ Creates a LuauExecutionTask pinned to a specific place version. ]]
function luau_execute.create_task_versioned(
	universe_id: string,
	place_id: string,
	version: string,
	script: buffer | string,
	timeout: number?,
	enable_binary_output: boolean?,
	binary_input: (buffer | string)?
): LuauExecutionTask
	local t = timeout or MAX_EXECUTION_TIME
	if t < 1 or t > MAX_EXECUTION_TIME then
		error(`specified timeout is outside of acceptable range [1, {MAX_EXECUTION_TIME}]`)
	end

	local script_str: string = if type(script) == "buffer" then buffer.tostring(script) else script

	local input_path: string? = nil
	if binary_input ~= nil then
		input_path = upload_input(binary_input, universe_id)
	end

	return make_task(
		string.format(TASK_CREATE_VERSIONED, universe_id, place_id, version),
		script_str,
		t,
		enable_binary_output,
		input_path
	)
end

function luau_execute.check_status(task_: LuauExecutionTask): LuauTaskState
	return query_status(task_).state
end

--[[
	Polls the task's status until it leaves PROCESSING. Yielding backs off
	exponentially up to `MAX_QUERY_YIELD` seconds. Returns true if the task
	finished with state COMPLETE.
]]
function luau_execute.await_finish(task_: LuauExecutionTask, timeout: number?): boolean
	local deadline = (timeout or MAX_EXECUTION_TIME)
	local started = os.clock()
	local yield = 0.1

	local status: LuauTaskState = luau_execute.check_status(task_)
	if status ~= "PROCESSING" then
		return status == "COMPLETE"
	end

	repeat
		task.wait(yield)
		yield = math.min(yield * 2, MAX_QUERY_YIELD)
		status = luau_execute.check_status(task_)
	until (status :: LuauTaskState) ~= "PROCESSING" or os.clock() - started >= deadline

	return (status :: LuauTaskState) == "COMPLETE"
end

function luau_execute.get_flat_logs(task_: LuauExecutionTask): { string }
	local logs = get_logs(task_, "FLAT")
	local entry = logs.luauExecutionSessionTaskLogs[1]
	return if entry and entry.messages then entry.messages else {}
end

function luau_execute.get_structured_logs(task_: LuauExecutionTask): { StructuredLog }
	local logs = get_logs(task_, "STRUCTURED")
	local entry = logs.luauExecutionSessionTaskLogs[1]
	return if entry and entry.structuredMessages then entry.structuredMessages else {}
end

function luau_execute.get_binary_output(task_: LuauExecutionTask): buffer
	local status = query_status(task_)
	assert(status.binaryOutputUri, "task was not created with binary output enabled")
	local response = net.request(status.binaryOutputUri, {
		method = "GET",
		headers = {
			["User-Agent"] = USER_AGENT,
			["X-API-Key"] = api_key(),
		},
	})
	if not response.ok then
		error(failure_message("fetch binary output", response))
	end
	return buffer.fromstring(response.body)
end

--[[
	Returns the task's error if it did not complete successfully. If the task
	is still processing, waits for it to finish first.
]]
function luau_execute.get_error(task_: LuauExecutionTask): TaskError?
	local status = query_status(task_)
	if status.state ~= "PROCESSING" then
		return status.error
	end
	luau_execute.await_finish(task_)
	return query_status(task_).error
end

function luau_execute.get_output(task_: LuauExecutionTask): { any }
	local status = query_status(task_)
	if not status.output then
		return {}
	end
	return status.output.results
end

function luau_execute.session_id(task_: LuauExecutionTask): string?
	local _, session = string.match(task_.path, ID_PATTERN)
	return session
end

function luau_execute.task_id(task_: LuauExecutionTask): string?
	local task_id, _ = string.match(task_.path, ID_PATTERN)
	return task_id
end

--[[ Overrides the API key read from the environment. Pass nil to clear. ]]
function luau_execute.set_api_key(key: (buffer | string)?)
	if type(key) == "buffer" then
		api_key_override = buffer.tostring(key)
	elseif type(key) == "string" then
		api_key_override = key
	else
		api_key_override = nil
	end
end

return luau_execute
