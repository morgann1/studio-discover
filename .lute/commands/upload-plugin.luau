--[[
	Upload Plugin Command

	Publishes a built .rbxm as a new version of the Creator Store plugin asset
	by submitting a Luau Execution Task through Open Cloud. Open Cloud's direct
	asset-update endpoint cannot update Plugin-type assets, so the upload is
	tunneled through `AssetService:CreateAssetVersionAsync` running inside a
	task on a Roblox place.

	Reads these from the environment:
	  - ROBLOX_API_KEY      API key with Luau Execution + Assets write scopes
	  - ROBLOX_UNIVERSE_ID  Universe owning the task-running place
	  - ROBLOX_PLACE_ID     Place used to run the task

	Pre-release tags (anything after vMAJOR.MINOR.PATCH, e.g. v1.2.3-rc1) are
	detected and cause a successful exit without uploading.
]]

local fs = require("@lute/fs")
local process = require("@lute/process")

local color = require("../utils/color")
local luau_execute = require("../lib/opencloud")

local uploadPlugin = {}

uploadPlugin.name = "upload-plugin"
uploadPlugin.description = "Uploads a built .rbxm as a new Creator Store plugin version"
uploadPlugin.usage = "lute run upload-plugin <path> [--tag vX.Y.Z]"

uploadPlugin.arguments = {
	{
		name = "path",
		kind = "positional",
		options = {
			help = "Path to the .rbxm to upload",
			required = true,
		},
	},
	{
		name = "tag",
		kind = "option",
		options = {
			help = "Release tag (used only to skip pre-releases); defaults to wally.toml version",
			aliases = { "t" },
		},
	},
}

export type Options = {
	path: string,
	tag: string?,
}

local SCRIPT_PATH = ".lute/scripts/plugin-upload.luau"
local WALLY_TOML_PATH = "plugin/wally.toml"
local TASK_TIMEOUT_SECONDS = 300

local function readFile(path: string): string
	local handle = fs.open(path, "r")
	local contents = fs.read(handle)
	fs.close(handle)
	return contents
end

local function readWallyVersion(): string
	local contents = readFile(WALLY_TOML_PATH)
	local version = contents:match('version%s*=%s*"([^"]+)"')
	assert(version, `Could not parse version from {WALLY_TOML_PATH}`)
	return version
end

--[[ Returns true when the version string has any trailing identifier after MAJOR.MINOR.PATCH. ]]
local function isPreRelease(raw: string): boolean
	local _major, _minor, _patch, rest = string.match(raw, "^v?(%d+)%.(%d+)%.(%d+)(.*)$")
	return rest ~= nil and rest ~= ""
end

local function requireEnv(name: string): string
	local value = process.env[name]
	if not value or value == "" then
		print(color.red(`Missing required environment variable: {name}`))
		process.exit(1)
	end
	return value :: string
end

local function printLogs(logs: { luau_execute.StructuredLog })
	for _, log in logs do
		if log.messageType == "ERROR" then
			print(color.red(log.message))
		elseif log.messageType == "WARNING" then
			print(color.yellow(log.message))
		elseif log.messageType == "INFO" then
			print(color.cyan(log.message))
		else
			print(log.message)
		end
	end
end

function uploadPlugin.run(options: Options)
	local pluginPath = options.path
	local tag = options.tag or readWallyVersion()

	if isPreRelease(tag) then
		print(color.dim(`Skipping Creator Store upload for pre-release {tag}`))
		return
	end

	if not fs.exists(pluginPath) or fs.type(pluginPath) ~= "file" then
		print(color.red(`Plugin file not found at {pluginPath}`))
		process.exit(1)
	end

	local universeId = requireEnv("ROBLOX_UNIVERSE_ID")
	local placeId = requireEnv("ROBLOX_PLACE_ID")
	requireEnv("ROBLOX_API_KEY")

	local pluginBytes = readFile(pluginPath)
	local script = readFile(SCRIPT_PATH)

	print(color.cyan(`→ Submitting Creator Store upload task ({#pluginBytes} bytes)`))
	local task = luau_execute.create_task_latest(
		universeId,
		placeId,
		script,
		TASK_TIMEOUT_SECONDS,
		false,
		buffer.fromstring(pluginBytes)
	)

	print(color.dim(`  task path: {task.path}`))
	print(color.cyan("→ Waiting for task to finish"))
	local success = luau_execute.await_finish(task, TASK_TIMEOUT_SECONDS)

	local logs = luau_execute.get_structured_logs(task)
	if #logs > 0 then
		print()
		print(color.bold("Task output:"))
		printLogs(logs)
		print()
	end

	if not success then
		local err = luau_execute.get_error(task)
		if err then
			print(color.red(`Task failed: {err.code} - {err.message}`))
		else
			print(color.red("Task did not finish successfully"))
		end
		process.exit(1)
	end

	print(color.bold(color.green("Creator Store upload succeeded")))
end

return uploadPlugin
