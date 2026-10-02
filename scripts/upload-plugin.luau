--!strict

--[[
	Publishes a built .rbxm as a new version of the Creator Store plugin. The release
		workflow is what normally runs this.

	Open Cloud cannot update a Plugin asset directly, so the upload runs
		`scripts/tasks/upload-plugin.luau` as a Luau Execution task on a Roblox place,
		with the .rbxm as the task's binary input.

	Reads these from the environment:
		ROBLOX_API_KEY      an API key with Luau Execution and Assets write scopes
		ROBLOX_UNIVERSE_ID  the universe that owns the task's place
		ROBLOX_PLACE_ID     the place the task runs on

	A pre-release tag, anything after vMAJOR.MINOR.PATCH such as v1.2.3-rc1, exits
		successfully without uploading.

	Usage: lute scripts/upload-plugin.luau <path> [--tag vX.Y.Z]
]]

const fs = require("@std/fs")
const process = require("@lute/process")

const color = require("@scripts/lib/color")
const createLuauTaskAsync = require("@scripts/lib/luau-execution/createLuauTaskAsync")
const getLuauTaskLogsAsync = require("@scripts/lib/luau-execution/getLuauTaskLogsAsync")
const parseArgs = require("@scripts/lib/parseArgs")
const project = require("@root/project")
const readPluginVersionAsync = require("@scripts/lib/readPluginVersionAsync")
const uploadBinaryInputAsync = require("@scripts/lib/luau-execution/uploadBinaryInputAsync")
const waitForTaskCompletionAsync = require("@scripts/lib/luau-execution/waitForTaskCompletionAsync")

const TASK_PATH = `{project.TASKS_PATH}/upload-plugin.luau`
const TASK_TIMEOUT_SECONDS = 300

const LOG_COLORS: { [getLuauTaskLogsAsync.MessageType]: color.Styler? } = {
	ERROR = color.red,
	WARNING = color.yellow,
	INFO = color.cyan,
}

table.freeze(LOG_COLORS)

const function requireEnv(name: string): string
	const value = process.env[name]
	if value == nil or value == "" then
		print(color.red(`Missing required environment variable: {name}`))
		process.exit(1)
	end

	return value
end

const function isPreRelease(tag: string): boolean
	const rest = string.match(tag, "^v?%d+%.%d+%.%d+(.*)$")
	return rest ~= nil and rest ~= ""
end

const args = parseArgs({ "tag", "t" })
const pluginPath = args.positionals[1]
if pluginPath == nil then
	print(color.red("Usage: lute scripts/upload-plugin.luau <path> [--tag vX.Y.Z]"))
	process.exit(1)
end

const tag = args.values.tag or args.values.t or readPluginVersionAsync()
if isPreRelease(tag) then
	print(color.dim(`Skipping the Creator Store upload for pre-release {tag}`))
	process.exit(0)
end

if not fs.exists(pluginPath) or fs.type(pluginPath) ~= "file" then
	print(color.red(`Plugin file not found at {pluginPath}`))
	process.exit(1)
end

const apiKey = requireEnv("ROBLOX_API_KEY")
const universeId = requireEnv("ROBLOX_UNIVERSE_ID")
const placeId = requireEnv("ROBLOX_PLACE_ID")

const plugin = fs.readFileToString(pluginPath)

print(color.cyan(`Uploading {pluginPath} ({#plugin} bytes)`))
const binaryInput = uploadBinaryInputAsync(universeId, apiKey, plugin)

const createdTask = createLuauTaskAsync({
	universeId = universeId,
	placeId = placeId,
	apiKey = apiKey,
	script = fs.readFileToString(TASK_PATH),
	timeoutSeconds = TASK_TIMEOUT_SECONDS,
	binaryInput = binaryInput,
})

print(color.cyan(`Waiting for {createdTask.path}`))
const finishedTask = waitForTaskCompletionAsync(createdTask.path, apiKey)

for _, log in getLuauTaskLogsAsync(createdTask.path, apiKey) do
	const style = LOG_COLORS[log.messageType]
	print(if style ~= nil then style(log.message) else log.message)
end

if finishedTask.state ~= "COMPLETE" then
	const reason = if finishedTask.error ~= nil
		then `{finishedTask.error.code}: {finishedTask.error.message}`
		else finishedTask.state
	print(color.red(`Creator Store upload failed. {reason}`))
	process.exit(1)
end

print(color.bold(color.green("Creator Store upload succeeded")))
